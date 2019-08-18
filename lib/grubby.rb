require "active_support/all"
require "casual_support"
require "gorge"
require "mechanize"
require "mini_sanity"
require "pleasant_path"
require "ryoba"

require_relative "grubby/version"
require_relative "grubby/log"

require_relative "grubby/core_ext/string"
require_relative "grubby/core_ext/uri"
require_relative "grubby/mechanize/fetch_with_retry"
require_relative "grubby/mechanize/download"
require_relative "grubby/mechanize/file"
require_relative "grubby/mechanize/link"
require_relative "grubby/mechanize/page"
require_relative "grubby/mechanize/parser"


class Grubby < Mechanize

  VERSION = GRUBBY_VERSION

  # The enforced minimum amount of time to wait between requests, in
  # seconds.  If the value is a Range, a random number within the Range
  # is chosen for each request.
  #
  # @return [Integer, Float, Range<Integer>, Range<Float>]
  attr_accessor :time_between_requests

  # Journal file used to ensure only-once processing of resources by
  # {singleton} across multiple program runs.
  #
  # @return [Pathname, nil]
  attr_reader :journal

  # @param journal [Pathname, String]
  #   Optional journal file used to ensure only-once processing of
  #   resources by {singleton} across multiple program runs.
  def initialize(journal = nil)
    super()

    # Prevent "memory leaks", and prevent mistakenly blank urls from
    # resolving.  (Blank urls resolve as a path relative to the last
    # history entry.  Without this setting, an erroneous `agent.get("")`
    # could sometimes successfully fetch a page.)
    self.max_history = 0

    # Prevent files of unforeseen content type from being buffered into
    # memory by default, in case they are very large.  However, increase
    # the threshold for what is considered "large", to prevent
    # unnecessary writes to disk.
    #
    # References:
    #   - http://docs.seattlerb.org/mechanize/Mechanize/PluggableParser.html
    #   - http://docs.seattlerb.org/mechanize/Mechanize/Download.html
    #   - http://docs.seattlerb.org/mechanize/Mechanize/File.html
    self.max_file_buffer = 1_000_000 # only applies to Mechanize::Download
    self.pluggable_parser.default = Mechanize::Download
    self.pluggable_parser["text/plain"] = Mechanize::File
    self.pluggable_parser["application/json"] = Grubby::JsonParser

    # Set up configurable rate limiting, and choose a reasonable default
    # rate limit.
    self.pre_connect_hooks << Proc.new{ self.send(:sleep_between_requests) }
    self.post_connect_hooks << Proc.new do |agent, uri, response, body|
      self.send(:mark_last_request_time, (Time.now unless response.code.to_s.start_with?("3")))
    end
    self.time_between_requests = 1.0

    self.journal = journal
  end

  # Sets the journal file used to ensure only-once processing of
  # resources by {singleton} across multiple program runs.  Setting the
  # journal file will clear the in-memory list of previously-processed
  # resources, and, if the journal file exists, load the list from file.
  #
  # @param path [Pathname, String, nil]
  # @return [Pathname]
  def journal=(path)
    @journal = path&.to_pathname&.touch_file
    @seen = if @journal
        require "csv"
        CSV.read(@journal).map{|row| SingletonKey.new(*row) }.to_set
      else
        Set.new
      end
    @journal
  end

  # Calls +#head+ and returns true if the result has response code
  # "200".  Unlike +#head+, error response codes (e.g. "404", "500")
  # do not cause a +Mechanize::ResponseCodeError+ to be raised.
  #
  # @param uri [URI, String]
  # @return [Boolean]
  def ok?(uri, query_params = {}, headers = {})
    begin
      head(uri, query_params, headers).code == "200"
    rescue Mechanize::ResponseCodeError
      false
    end
  end

  # Calls +#get+ with each of +mirror_uris+ until a successful
  # ("200 OK") response is recieved, and returns that +#get+ result.
  # Rescues and logs +Mechanize::ResponseCodeError+ failures for all but
  # the last mirror.
  #
  # @example
  #   grubby = Grubby.new
  #
  #   urls = [
  #     "http://httpstat.us/404",
  #     "http://httpstat.us/500",
  #     "http://httpstat.us/200#foo",
  #     "http://httpstat.us/200#bar",
  #   ]
  #
  #   grubby.get_mirrored(urls).uri  # == URI("http://httpstat.us/200#foo")
  #
  #   grubby.get_mirrored(urls.take(2))  # raise Mechanize::ResponseCodeError
  #
  # @param mirror_uris [Array<URI>, Array<String>]
  # @return [Mechanize::Page, Mechanize::File, Mechanize::Download, ...]
  # @raise [Mechanize::ResponseCodeError]
  #   if all +mirror_uris+ fail
  def get_mirrored(mirror_uris, parameters = [], referer = nil, headers = {})
    i = 0
    begin
      get(mirror_uris[i], parameters, referer, headers)
    rescue Mechanize::ResponseCodeError => e
      i += 1
      if i >= mirror_uris.length
        raise
      else
        $log.debug("Mirror failed (code #{e.response_code}): #{mirror_uris[i - 1]}")
        $log.debug("Try mirror: #{mirror_uris[i]}")
        retry
      end
    end
  end

  # Ensures only-once processing of the resource indicated by +uri+ for
  # the specified +purpose+.  A list of previously-processed resource
  # URIs and content hashes is maintained in the Grubby instance.  The
  # given block is called with the fetched resource only if the
  # resource's URI and the resource's content hash have not been
  # previously processed under the specified +purpose+.
  #
  # @example
  #   grubby = Grubby.new
  #
  #   grubby.singleton("https://example.com/foo") do |page|
  #     # will be executed (first time "/foo")
  #   end
  #
  #   grubby.singleton("https://example.com/foo#bar") do |page|
  #     # will be skipped (already seen "/foo")
  #   end
  #
  #   grubby.singleton("https://example.com/foo", "again!") do |page|
  #     # will be executed (new purpose for "/foo")
  #   end
  #
  # @param uri [URI, String]
  # @param purpose [String]
  # @yield [resource]
  # @yieldparam resource [Mechanize::Page, Mechanize::File, Mechanize::Download, ...]
  # @return [Boolean]
  #   whether the given block was called
  # @raise [Mechanize::ResponseCodeError]
  #   if fetching the resource results in error (see +Mechanize#get+)
  def singleton(uri, purpose = "")
    series = []

    uri = uri.to_absolute_uri
    return if try_skip_singleton(uri, purpose, series)

    normalized_uri = normalize_uri(uri)
    return if try_skip_singleton(normalized_uri, purpose, series)

    $log.info("Fetch #{normalized_uri}")
    resource = get(normalized_uri)
    skip = try_skip_singleton(resource.uri, purpose, series) |
      try_skip_singleton("content hash: #{resource.content_hash}", purpose, series)

    yield resource unless skip

    CSV.open(journal, "a") do |csv|
      series.each{|singleton_key| csv << singleton_key }
    end if journal

    !skip
  end


  private

  # @!visibility private
  SingletonKey = Struct.new(:purpose, :target)

  def try_skip_singleton(target, purpose, series)
    series << SingletonKey.new(purpose, target.to_s)
    if series.uniq!.nil? && !@seen.add?(series.last)
      seen_info = series.length > 1 ? "seen #{series.last.target}" : "seen"
      $log.info("Skip #{series.first.target} (#{seen_info})")
      true
    end
  end

  def normalize_uri(uri)
    uri = uri.dup
    $log.warn("Ignore ##{uri.fragment} in #{uri}") if uri.fragment
    uri.fragment = nil
    uri.path = uri.path.chomp("/")
    uri
  end

  def sleep_between_requests
    @last_request_at ||= 0.0
    delay_duration = time_between_requests.is_a?(Range) ?
      rand(time_between_requests) : time_between_requests
    sleep_duration = @last_request_at + delay_duration - Time.now.to_f
    sleep(sleep_duration) if sleep_duration > 0
  end

  def mark_last_request_time(time)
    @last_request_at = time.to_f
  end

end


require_relative "grubby/json_parser"
require_relative "grubby/scraper"
require_relative "grubby/page_scraper"
require_relative "grubby/json_scraper"


$grubby = Grubby.new

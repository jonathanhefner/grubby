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

  # The minimum amount of time enforced between requests, in seconds.
  # If the value is a Range, a random number within the Range is chosen
  # for each request.
  #
  # @return [Integer, Float, Range<Integer>, Range<Float>]
  attr_accessor :time_between_requests

  # Journal file used to ensure only-once processing of resources by
  # {fulfill} across multiple program runs.
  #
  # @return [Pathname, nil]
  attr_reader :journal

  # @param journal [Pathname, String]
  #   Optional journal file used to ensure only-once processing of
  #   resources by {fulfill} across multiple program runs
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
  # resources by {fulfill} across multiple program runs.  Setting the
  # journal file will clear the in-memory list of previously-processed
  # resources, and, if the journal file exists, load the list from file.
  #
  # @param path [Pathname, String, nil]
  # @return [Pathname]
  def journal=(path)
    @journal = path&.to_pathname&.touch_file
    @fulfilled = if @journal
        require "csv"
        CSV.read(@journal).map{|row| FulfilledEntry.new(*row) }.to_set
      else
        Set.new
      end
    @journal
  end

  # Calls +#head+ and returns true if a response code "200" is received,
  # false otherwise.  Unlike +#head+, error response codes (e.g. "404",
  # "500") do not result in a +Mechanize::ResponseCodeError+ being
  # raised.
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
  # ("200 OK") response is received, and returns that +#get+ result.
  # Rescues and logs +Mechanize::ResponseCodeError+ failures for all but
  # the last mirror.
  #
  # @example
  #   grubby = Grubby.new
  #
  #   urls = [
  #     "https://httpstat.us/404",
  #     "https://httpstat.us/500",
  #     "https://httpstat.us/200?foo",
  #     "https://httpstat.us/200?bar",
  #   ]
  #
  #   grubby.get_mirrored(urls).uri  # == URI("https://httpstat.us/200?foo")
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
  # the specified +purpose+.  The given block is executed and the result
  # is returned if and only if the Grubby instance has not recorded a
  # previous call to +fulfill+ for the same resource and purpose.
  #
  # Note that the resource is identified by both its URI and its content
  # hash.  The latter prevents superfluous and rearranged URI query
  # string parameters from interfering with only-once processing.
  #
  # If {journal} is set, and if the block does not raise an exception,
  # the resource and purpose are logged to the journal file.  This
  # enables only-once processing across multiple program runs.  It also
  # provides a means to resume batch processing after an unexpected
  # termination.
  #
  # @example
  #   grubby = Grubby.new
  #
  #   grubby.fulfill("https://example.com/posts") do |page|
  #     "first time"
  #   end
  #   # == "first time"
  #
  #   grubby.fulfill("https://example.com/posts") do |page|
  #     "already seen" # not evaluated
  #   end
  #   # == nil
  #
  #   grubby.fulfill("https://example.com/posts?page=1") do |page|
  #     "already seen content hash" # not evaluated
  #   end
  #   # == nil
  #
  #   grubby.fulfill("https://example.com/posts", "again!") do |page|
  #     "already seen, but new purpose"
  #   end
  #   # == "already seen, but new purpose"
  #
  # @param uri [URI, String]
  # @param purpose [String]
  # @yieldparam resource [Mechanize::Page, Mechanize::File, Mechanize::Download, ...]
  # @yieldreturn [Object]
  # @return [Object, nil]
  # @raise [Mechanize::ResponseCodeError]
  #   if fetching the resource results in error (see +Mechanize#get+)
  def fulfill(uri, purpose = "")
    series = []

    uri = uri.to_absolute_uri
    return unless add_fulfilled(uri, purpose, series)

    normalized_uri = normalize_uri(uri)
    return unless add_fulfilled(normalized_uri, purpose, series)

    $log.info("Fetch #{normalized_uri}")
    resource = get(normalized_uri)
    unprocessed = add_fulfilled(resource.uri, purpose, series) &
      add_fulfilled("content hash: #{resource.content_hash}", purpose, series)

    result = yield resource if unprocessed

    CSV.open(journal, "a") do |csv|
      series.each{|entry| csv << entry }
    end if journal

    result
  end


  private

  # @!visibility private
  FulfilledEntry = Struct.new(:purpose, :target)

  def add_fulfilled(target, purpose, series)
    series << FulfilledEntry.new(purpose, target.to_s)
    if (series.uniq!) || @fulfilled.add?(series.last)
      true
    else
      $log.info("Skip #{series.first.target}" \
        " (seen#{" #{series.last.target}" unless series.length == 1})")
      false
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

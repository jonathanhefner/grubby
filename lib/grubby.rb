require "active_support/all"
require "casual_support"
require "dumb_delimited"
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


class Grubby < Mechanize

  VERSION = GRUBBY_VERSION

  # @return [Integer, Float, Range<Integer>, Range<Float>]
  #   The enforced minimum amount of time to wait between requests, in
  #   seconds.  If the value is a Range, a random number within the
  #   Range is chosen for each request.
  attr_accessor :time_between_requests

  # @param singleton_journal [Pathname, String]
  #   Optional journal file to persist the list of resources processed
  #   by {singleton}.  Useful to ensure only-once processing across
  #   multiple program runs.
  def initialize(singleton_journal = nil)
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
    self.time_between_requests = 1.0

    @journal = singleton_journal.try(&:to_pathname).try(&:touch_file)
    @seen = @journal ? SingletonKey.parse_file(@journal).index_to{ true } : {}
  end

  # Calls +#get+ with each of +mirror_uris+ until a successful
  # ("200 OK") response is recieved, and returns that +#get+ result.
  # Rescues and logs +Mechanize::ResponseCodeError+ failures for all but
  # the last mirror.
  #
  # @param mirror_uris [Array<String>]
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

  # Ensures only-once processing of the resource indicated by +target+
  # for the specified +purpose+.  A list of previously-processed
  # resource URIs and content hashes is maintained in the Grubby
  # instance.  The given block is called with the fetched resource only
  # if the resource's URI and the resource's content hash have not been
  # previously processed under the specified +purpose+.
  #
  # @param target [URI, String, Mechanize::Page::Link, #to_absolute_uri]
  #   designates the resource to fetch
  # @param purpose [String]
  #   the purpose of processing the resource
  # @yield [resource]
  #   processes the resource
  # @yieldparam resource [Mechanize::Page, Mechanize::File, Mechanize::Download, ...]
  #   the fetched resource
  # @return [Boolean]
  #   whether the given block was called
  # @raise [Mechanize::ResponseCodeError]
  #   if fetching the resource results in error (see +Mechanize#get+)
  def singleton(target, purpose = "")
    series = []

    original_uri = target.to_absolute_uri
    return if try_skip_singleton(original_uri, purpose, series)

    normalized_uri = normalize_uri(original_uri)
    return if try_skip_singleton(normalized_uri, purpose, series)

    $log.info("Fetch #{normalized_uri}")
    resource = get(normalized_uri)
    skip = try_skip_singleton(resource.uri, purpose, series) |
      try_skip_singleton("content hash: #{resource.content_hash}", purpose, series)

    yield resource unless skip

    series.append_to_file(@journal) if @journal

    !skip
  end


  private

  SingletonKey = DumbDelimited[:purpose, :target]

  def try_skip_singleton(target, purpose, series)
    series << SingletonKey.new(purpose, target.to_s)
    if series.uniq!.nil? && @seen.displace(series.last, true)
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
    delay_duration = @time_between_requests.is_a?(Range) ?
      rand(@time_between_requests) : @time_between_requests
    sleep_duration = @last_request_at + delay_duration - Time.now.to_f
    sleep(sleep_duration) if sleep_duration > 0
    @last_request_at = Time.now.to_f
  end

end


require_relative "grubby/json_parser"
require_relative "grubby/scraper"
require_relative "grubby/page_scraper"
require_relative "grubby/json_scraper"

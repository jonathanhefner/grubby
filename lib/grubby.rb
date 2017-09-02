require "active_support/all"
require "casual_support"
require "dumb_delimited"
require "gorge"
require "mechanize"
require "mini_sanity"
require "pleasant_path"

require_relative "grubby/log"

require_relative "grubby/core_ext/string"
require_relative "grubby/core_ext/uri"
require_relative "grubby/mechanize/fetch_with_retry"
require_relative "grubby/mechanize/download"
require_relative "grubby/mechanize/file"
require_relative "grubby/mechanize/link"
require_relative "grubby/mechanize/page"
require_relative "grubby/nokogiri/searchable"


class Grubby < Mechanize

  # @return [Integer, Float, Range<Integer>, Range<Float>]
  #   The enforced minimum amount of time to wait between requests, in
  #   seconds.  If the value is a Range, a random number within the
  #   Range is chosen for each request.
  attr_accessor :time_between_requests

  def initialize
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
    self.pluggable_parser["application/json"] = Mechanize::File

    # Set up configurable rate limiting, and choose a reasonable default
    # rate limit.
    self.pre_connect_hooks << Proc.new{ self.send(:sleep_between_requests) }
    self.time_between_requests = 1.0
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
        $log.info("Mirror failed with response code #{e.response_code}: #{mirror_uris[i - 1]}")
        $log.debug("Trying next mirror: #{mirror_uris[i]}")
        retry
      end
    end
  end


  private

  def sleep_between_requests
    @last_request_at ||= 0.0
    delay_duration = @time_between_requests.is_a?(Range) ?
      rand(@time_between_requests) : @time_between_requests
    sleep_duration = @last_request_at + delay_duration - Time.now.to_f
    sleep(sleep_duration) if sleep_duration > 0
    @last_request_at = Time.now.to_f
  end

end


require_relative "grubby/version"

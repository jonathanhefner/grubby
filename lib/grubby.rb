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
  end

end


require_relative "grubby/version"

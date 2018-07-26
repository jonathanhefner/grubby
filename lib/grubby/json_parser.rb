class Grubby::JsonParser < Mechanize::File

  # Returns the options to use when parsing JSON.  The returned options
  # Hash is not +dup+ed and can be modified directly.  Any modifications
  # will be applied to all future parsing.
  #
  # For information about available options, see
  # {http://ruby-doc.org/stdlib/libdoc/json/rdoc/JSON.html#method-i-parse
  # +JSON.parse+}.
  #
  # @return [Hash]
  def self.json_parse_options
    @json_parse_options ||= {
      max_nesting: false,
      allow_nan: false,
      symbolize_names: false,
      create_additions: false,
      object_class: Hash,
      array_class: Array,
    }
  end

  # Sets the options to use when parsing JSON.  The entire options Hash
  # is replaced, and the new value will be applied to all future
  # parsing.  To set options individually, see {json_parse_options}.
  #
  # For information about available options, see
  # {http://ruby-doc.org/stdlib/libdoc/json/rdoc/JSON.html#method-i-parse
  # +JSON.parse+}.
  #
  # @param options [Hash]
  def self.json_parse_options=(options)
    @json_parse_options = options
  end

  # The parsed JSON data.
  #
  # @return [Hash, Array]
  attr_reader :json

  def initialize(uri = nil, response = nil, body = nil, code = nil)
    @json = body && JSON.parse(body, self.class.json_parse_options)
    super
  end

end

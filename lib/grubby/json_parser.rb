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
    @json_parse_options ||= JSON.load_default_options.merge(create_additions: false)
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

  # The Mechanize agent used to make the request.
  #
  # @return [Mechanize, nil]
  attr_accessor :mech

  def initialize(uri = nil, response = nil, body = nil, code = nil, mech = nil)
    @json = body.presence && JSON.parse(body, self.class.json_parse_options)
    @mech = mech
    super(uri, response, body, code)
  end

end

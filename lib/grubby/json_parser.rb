class Grubby::JsonParser < Mechanize::File

  # The parsed JSON data.
  #
  # @return [Hash, Array]
  attr_reader :json

  # The Mechanize agent used to make the request.
  #
  # @return [Mechanize, nil]
  attr_accessor :mech

  def initialize(uri = nil, response = nil, body = nil, code = nil, mech = nil)
    @json = JSON.load(body, nil, create_additions: false)
    @mech = mech
    super(uri, response, body, code)
  end

end

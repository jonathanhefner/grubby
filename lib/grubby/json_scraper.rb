class Grubby::JsonScraper < Grubby::Scraper

  # The parsed JSON data being scraped.
  #
  # @return [Hash, Array]
  attr_reader :json

  # @param source [Grubby::JsonParser]
  def initialize(source)
    @json = source.assert_kind_of!(Grubby::JsonParser).json
    super
  end

end

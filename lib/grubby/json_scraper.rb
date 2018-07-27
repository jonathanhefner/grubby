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

  # Scrapes a locally-stored file.  This method is intended for use with
  # subclasses of +Grubby::JsonScraper+.
  #
  # @example
  #   class MyScraper < Grubby::JsonScraper
  #     # ...
  #   end
  #
  #   MyScraper.scrape_file("path/to/local_file.json").class  # == MyScraper
  #
  # @param path [String]
  # @return [Grubby::JsonScraper]
  def self.scrape_file(path)
    uri = URI.join("file:///", File.expand_path(path))
    body = File.read(path)
    self.new(Grubby::JsonParser.new(uri, nil, body, "200"))
  end

end

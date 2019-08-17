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
  # @param agent [Mechanize]
  # @return [Grubby::JsonScraper]
  def self.scrape_file(path, agent = $grubby)
    self.new(Grubby::JsonParser.read_local(path).tap{|parser| parser.mech = agent })
  end

end

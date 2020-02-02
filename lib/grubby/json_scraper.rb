class Grubby::JsonScraper < Grubby::Scraper

  # The parsed JSON data being scraped.
  #
  # @return [Hash, Array]
  attr_reader :json

  # @param source [Grubby::JsonParser]
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def initialize(source)
    @json = source.assert!(Grubby::JsonParser).json
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
  #   MyScraper.scrape_file("path/to/local_file.json")  # === MyScraper
  #
  # @param path [String]
  # @param agent [Mechanize]
  # @return [Grubby::JsonScraper]
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def self.scrape_file(path, agent = $grubby)
    self.new(Grubby::JsonParser.read_local(path).tap{|parser| parser.mech = agent })
  end

end

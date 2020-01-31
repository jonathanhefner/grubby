class Grubby::PageScraper < Grubby::Scraper

  # The Page being scraped.
  #
  # @return [Mechanize::Page]
  attr_reader :page

  # @param source [Mechanize::Page]
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def initialize(source)
    @page = source.assert_kind_of!(Mechanize::Page)
    super
  end

  # Scrapes a locally-stored file.  This method is intended for use with
  # subclasses of +Grubby::PageScraper+.
  #
  # @example
  #   class MyScraper < Grubby::PageScraper
  #     # ...
  #   end
  #
  #   MyScraper.scrape_file("path/to/local_file.html")  # === MyScraper
  #
  # @param path [String]
  # @param agent [Mechanize]
  # @return [Grubby::PageScraper]
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def self.scrape_file(path, agent = $grubby)
    self.new(Mechanize::Page.read_local(path).tap{|page| page.mech = agent })
  end

end

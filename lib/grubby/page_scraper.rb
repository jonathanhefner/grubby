class Grubby::PageScraper < Grubby::Scraper

  # @return [Mechanize::Page]
  #   The Page being scraped.
  attr_reader :page

  # @param source [Mechanize::Page]
  def initialize(source)
    @page = source.assert_kind_of!(Mechanize::Page)
    super
  end

end

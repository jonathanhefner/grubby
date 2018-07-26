class Grubby::PageScraper < Grubby::Scraper

  # The Page being scraped.
  #
  # @return [Mechanize::Page]
  attr_reader :page

  # @param source [Mechanize::Page]
  def initialize(source)
    @page = source.assert_kind_of!(Mechanize::Page)
    super
  end

end

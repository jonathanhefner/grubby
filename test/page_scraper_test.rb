require "test_helper"

class GrubbyPageScraperTest < Minitest::Test

  def test_initialize_with_valid_parser
    page = Mechanize::Page.new
    scraper = Grubby::PageScraper.new(page)
    assert_same page, scraper.page
  end

  def test_initialize_with_invalid_parser
    download = Mechanize::Download.new
    assert_raises { Grubby::PageScraper.new(download) }
  end

end

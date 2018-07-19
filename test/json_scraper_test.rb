require "test_helper"

class GrubbyJsonScraperTest < Minitest::Test

  def test_initialize_with_valid_parser
    parser = Grubby::JsonParser.new(nil, nil, "[1, 2, 3]", nil)
    scraper = Grubby::JsonScraper.new(parser)
    assert_same parser.json, scraper.json
  end

  def test_initialize_with_invalid_parser
    page = Mechanize::Page.new
    assert_raises { Grubby::JsonScraper.new(page) }
  end

end

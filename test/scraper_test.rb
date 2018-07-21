require "test_helper"

class GrubbyScraperTest < Minitest::Test

  def test_scrapes_values
    scraper = make_scraper("R", "O")

    assert_equal "R", scraper.req_val
    assert_equal "O", scraper.opt_val
    assert_equal scraper.req_val, scraper.dup_val
  end

  def test_raises_on_missing_required_value
    assert_raises(Grubby::Scraper::Error){ make_scraper(nil, "O") }
  end

  def test_allows_missing_optional_value
    scraper = make_scraper("R", nil)

    assert_equal "R", scraper.req_val
    assert_nil scraper.opt_val
  end

  def test_reports_all_original_errors
    error = assert_raises(Grubby::Scraper::Error){ make_scraper("", "") }
    assert_match "req_val", error.message
    assert_match "opt_val", error.message
    refute_match "dup_val", error.message
  end

  def test_filters_error_backtrace
    error = assert_raises(Grubby::Scraper::Error){ make_scraper("", "") }
    ruby_file = Grubby::Scraper.method(:scrapes).source_location[0]
    refute_match ruby_file, error.message
  end

  def test_fields_attr
    assert_equal [:req_val, :opt_val, :dup_val].sort, MyScraper.fields.sort
  end

  def test_parser_attr
    scraper = make_scraper("R", "O")

    assert_instance_of MyParser, scraper.source
  end

  def test_lookup
    scraper = make_scraper("R", "O")

    assert_equal "R", scraper[:req_val]
    assert_equal "O", scraper[:opt_val]
    assert_equal scraper[:req_val], scraper[:dup_val]
  end

  def test_to_h
    scraper = make_scraper("R", "O")

    assert_equal({ req_val: "R", opt_val: "O", dup_val: "R" }, scraper.to_h)
  end

  private

  class MyParser < Mechanize::File
    attr_accessor :data
  end

  class MyScraper < Grubby::Scraper
    scrapes :req_val do
      raise if source.data.first.try(&:empty?)
      source.data.first
    end

    scrapes :opt_val, optional: true do
      raise if source.data.last.try(&:empty?)
      source.data.last
    end

    scrapes :dup_val do
      req_val
    end
  end

  def make_scraper(req_val, opt_val)
    parser = MyParser.new
    parser.data = [req_val, opt_val]

    silence_logging do
      MyScraper.new(parser)
    end
  end

end

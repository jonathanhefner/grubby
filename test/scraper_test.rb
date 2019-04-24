require "test_helper"

class GrubbyScraperTest < Minitest::Test

  def test_scrapes_values
    scraper = make_scraper(CONTENT)

    EXPECTED.each do |field, expected|
      assert_equal expected, scraper.send(field)
    end
  end

  def test_raises_on_nil_required_value
    assert_raises(Grubby::Scraper::Error) do
      make_scraper(CONTENT.merge(req: nil))
    end
  end

  def test_allows_nil_optional_value
    scraper = make_scraper(CONTENT.merge(opt: nil))

    assert_equal EXPECTED[:req_val], scraper.req_val # sanity check
    assert_nil scraper.opt_val
  end

  def test_captures_all_errors
    error = assert_raises(Grubby::Scraper::Error){ make_scraper({}) }

    assert_instance_of MyScraper, error.scraper
    EXPECTED.keys.each do |field|
      assert_kind_of StandardError, error.scraper.errors[field]
    end
  end

  def test_reports_only_original_errors
    error = assert_raises(Grubby::Scraper::Error){ make_scraper({}) }

    assert_match "req_val", error.message
    assert_match "opt_val", error.message
    refute_match "dup_val", error.message
  end

  def test_filters_error_backtrace
    error = assert_raises(Grubby::Scraper::Error){ make_scraper({}) }
    ruby_file = Grubby::Scraper.method(:scrapes).source_location[0]

    refute_match ruby_file, error.message
  end

  def test_fields_attr
    assert_equal EXPECTED.keys.sort, MyScraper.fields.sort
  end

  def test_fields_attr_includes_superclass_fields
    assert_equal INHERITING_EXPECTED.keys.sort, MyInheritingScraper.fields.sort
  end

  def test_source_attr
    scraper = make_scraper(CONTENT)

    assert_kind_of Mechanize::File, scraper.source
    assert_equal CONTENT, scraper.source.content
  end

  def test_lookup
    scraper = make_scraper(CONTENT)

    EXPECTED.each do |field, expected|
      assert_equal expected, scraper[field]
    end
  end

  def test_to_h
    scraper = make_scraper(CONTENT)

    assert_equal EXPECTED, scraper.to_h
  end

  def test_to_h_includes_superclass_fields
    scraper = make_scraper(CONTENT, MyInheritingScraper)

    assert_equal INHERITING_EXPECTED, scraper.to_h
  end

  def test_initialize_missing_super_raises_friendly_error
    error = assert_raises{ IncorrectScraper.new.foo }

    assert_match "initialize", error.message
  end

  def test_factory_method
    url = "http://localhost/response_code?code=200"
    scraper = DummyScraper.scrape(url)

    assert_instance_of DummyScraper, scraper
    assert_equal url, scraper.source.uri.to_s
    assert_same $grubby, scraper.source.mech
  end

  def test_factory_method_with_agent
    agent = Mechanize.new
    scraper = DummyScraper.scrape("http://localhost/response_code?code=200", agent)

    assert_same agent, scraper.source.mech
  end

  private

  CONTENT = {
    req: "required value",
    opt: "optional value",
  }

  EXPECTED = {
    req_val: "required value",
    dup_val: "required value",
    opt_val: "optional value",
  }

  INHERITING_EXPECTED = EXPECTED.merge(
    add_val: EXPECTED[:req_val],
  )

  class MyScraper < Grubby::Scraper
    scrapes :req_val do
      source.content.fetch(:req)
    end

    scrapes :opt_val, optional: true do
      source.content.fetch(:opt)
    end

    scrapes :dup_val do
      req_val
    end
  end

  class MyInheritingScraper < MyScraper
    scrapes :add_val do
      req_val
    end
  end

  def make_scraper(content, klass = MyScraper)
    source = Mechanize::File.new(nil, nil, content, nil)
    silence_logging do
      klass.new(source)
    end
  end

  class IncorrectScraper < Grubby::Scraper
    scrapes(:foo){ "FOO!" }

    def initialize(*args)
      # does not call `super`
    end
  end

  class DummyScraper < Grubby::Scraper
  end

end

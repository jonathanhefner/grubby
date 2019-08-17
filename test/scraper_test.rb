require "test_helper"

class GrubbyScraperTest < Minitest::Test

  def test_scrapes_values
    scraper = make_scraper(CONTENT)

    EXPECTED.each do |field, expected|
      assert_equal [expected], [scraper.send(field)]
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

  def test_obeys_conditional_modifiers
    scraper = make_scraper(CONTENT.merge(opt: nil))

    assert_nil scraper.opt_word
    refute_nil scraper.opt_miss
  end

  def test_captures_all_errors
    error = assert_raises(Grubby::Scraper::Error){ make_scraper({}) }

    assert_instance_of MyScraper, error.scraper
    EXPECTED.compact.keys.each do |field|
      assert_kind_of StandardError, error.scraper.errors[field]
    end
  end

  def test_reports_only_original_errors
    error = assert_raises(Grubby::Scraper::Error){ make_scraper({}) }

    assert_match "req_val", error.message
    assert_match "opt_val", error.message
    refute_match "opt_word", error.message
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
      assert_equal [expected], [scraper[field]]
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
    scraper = UrlScraper.scrape(UrlScraper.url)

    assert_instance_of UrlScraper, scraper
    assert_equal UrlScraper.url, scraper.url
    assert_same $grubby, scraper.source.mech
  end

  def test_factory_method_with_agent
    agent = Mechanize.new
    scraper = UrlScraper.scrape(UrlScraper.url, agent)

    assert_same agent, scraper.source.mech
  end

  def test_each
    [nil, :next_uri, :next_page].each do |method|
      expected_urls = (1..2).map{|i| UrlScraper.url(i) }.reverse
      expected_urls.each{|url| url << "##{method}" } if method
      actual_urls = []

      UrlScraper.each(expected_urls.first, { next_method: method }.compact) do |scraper|
        assert_instance_of UrlScraper, scraper
        assert_same $grubby, scraper.source.mech
        actual_urls << scraper.url
      end
      assert_equal expected_urls, actual_urls
    end
  end

  def test_each_with_agent
    agent = Mechanize.new

    UrlScraper.each(UrlScraper.url(2), agent) do |scraper|
      assert_same agent, scraper.source.mech
    end
  end

  def test_each_without_block
    [nil, :next_uri, :next_page].each do |method|
      args = [UrlScraper.url(2), ({ next_method: method } if method)].compact
      expected_urls = []
      UrlScraper.each(*args){|scraper| expected_urls << scraper.url }
      actual = UrlScraper.each(*args)

      assert_kind_of Enumerator, actual
      assert_equal expected_urls, actual.map(&:url)
    end
  end

  def test_each_with_invalid_next_method
    error = assert_raises NoMethodError do
      UrlScraper.each(UrlScraper.url(2), next_method: :nope) do |scraper|
        assert false # should never get here
      end
    end
    assert_equal :nope, error.name

    error = assert_raises NoMethodError do
      UrlScraper.each(UrlScraper.url(2), next_method: :nope)
    end
    assert_equal :nope, error.name
  end

  private

  CONTENT = {
    req: "required value",
    opt: "optional value",
  }

  EXPECTED = {
    req_val: "required value",
    opt_val: "optional value",
    opt_word: "optional",
    opt_miss: nil,
  }

  INHERITING_EXPECTED = EXPECTED.merge(
    opt_val: EXPECTED[:opt_val].swapcase,
    opt_word: EXPECTED[:opt_word].swapcase,
    add_val: EXPECTED[:req_val],
  )

  class MyScraper < Grubby::Scraper
    scrapes :req_val do
      source.content.fetch(:req)
    end

    scrapes :opt_val, optional: true do
      source.content.fetch(:opt)
    end

    scrapes :opt_word, if: :opt_val do
      opt_val[/\w+/]
    end

    scrapes :opt_miss, unless: :opt_val do
      true
    end
  end

  class MyInheritingScraper < MyScraper
    scrapes :opt_val, optional: true do
      source.content.fetch(:opt)&.swapcase
    end

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

  class UrlScraper < Grubby::Scraper
    def self.url(n = 1)
      "http://localhost/response_code?code=200&n=#{n}"
    end

    scrapes(:url){ source.uri.to_s }
    scrapes(:n){ source.uri.query[/\bn=(\d+)\b/, 1]&.to_i }

    def next
      self.class.url(n - 1) if n > 1
    end

    def next_uri
      self.next.try{|url| URI(url + "#next_uri") }
    end

    def next_page
      self.next.try{|url| source.mech.get(url + "#next_page") }
    end
  end

end

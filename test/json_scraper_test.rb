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

  def test_scrape_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "some file.json")
      hi = "Hello"
      File.write(path, "{ \"hi\": \"#{hi}\" }")
      scraper = MyScraper.scrape_file(path)

      assert_instance_of MyScraper, scraper
      assert_equal hi, scraper.hi
      assert_same $grubby, scraper.source.mech
    end
  end

  def test_scrape_file_with_agent
    Dir.mktmpdir do |dir|
      path = File.join(dir, "file.json")
      File.write(path, "{ \"hi\": \"...\" }")
      grubby = Grubby.new
      scraper = MyScraper.scrape_file(path, grubby)

      assert_same grubby, scraper.source.mech
    end
  end

  private

  class MyScraper < Grubby::JsonScraper
    scrapes(:hi){ json.fetch("hi") }
  end

end

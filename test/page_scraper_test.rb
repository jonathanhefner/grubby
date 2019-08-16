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

  def test_scrape_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "some file.html")
      h1 = "Hello"
      File.write(path, "<h1>#{h1}</h1>")
      scraper = MyScraper.scrape_file(path)

      assert_instance_of MyScraper, scraper
      assert_equal h1, scraper.h1
      assert_same $grubby, scraper.page.mech
    end
  end

  def test_scrape_file_with_agent
    Dir.mktmpdir do |dir|
      path = File.join(dir, "file.html")
      File.write(path, "<h1>...</h1>")
      grubby = Grubby.new
      scraper = MyScraper.scrape_file(path, grubby)

      assert_same grubby, scraper.page.mech
    end
  end

  private

  class MyScraper < Grubby::PageScraper
    scrapes(:h1){ page.at("h1").text }
  end

end

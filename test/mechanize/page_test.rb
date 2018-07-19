require "test_helper"

class MechanizePageTest < Mechanize::TestCase

  def test_searchbang_with_one_matching
    results = make_page.search!("#bad1", "#good2", "#bad2")
    assert_equal "good2", results.first.attr("id")
  end

  def test_atbang_with_multiple_matching
    result = make_page.at!("#good3", "#good2")
    assert_equal "good3", result.attr("id")
  end


  private

  def make_page
    html_page(<<-HTML)
      <html>
      <body>
        <p id="good1"></p>
        <p id="good2"></p>
        <p id="good3"></p>
      </body>
      </html>
    HTML
  end

end

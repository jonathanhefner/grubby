require "test_helper"

class NokogiriSearchableTest < Minitest::Test

  def test_searchbang_with_some_matching
    [
      ["#good1"],
      ["#good1", "#good3"],
      ["#good2", "#good3", "#good1"],
      ["#good1", "#bad1", "#bad2"],
      ["#bad1", "#bad2", "#good1"],
    ].each do |queries|
      searchable = make_searchable
      assert_equal searchable.search(*queries), searchable.search!(*queries)
    end
  end

  def test_searchbang_with_none_matching
    error = assert_raises { make_searchable.search!("#bad1", "#bad2") }
    assert_match "#bad1", error.message
    assert_match "#bad2", error.message
  end

  def test_atbang_with_some_matching
    [
      ["#good1"],
      ["#good1", "#good3"],
      ["#good2", "#good3", "#good1"],
      ["#good1", "#bad1", "#bad2"],
      ["#bad1", "#bad2", "#good1"],
    ].each do |queries|
      searchable = make_searchable
      assert_equal searchable.at(*queries), searchable.at!(*queries)
    end
  end

  def test_atbang_with_none_matching
    error = assert_raises { make_searchable.at!("#bad1", "#bad2") }
    assert_match "#bad1", error.message
    assert_match "#bad2", error.message
  end


  private

  def make_searchable
    Nokogiri::XML(<<-XML)
      <root>
        <item id="good1" />
        <item id="good2" />
        <item id="good3" />
      </root>
    XML
  end

end

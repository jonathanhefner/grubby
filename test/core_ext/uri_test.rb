require "test_helper"

class URITest < Minitest::Test

  def test_basename
    ["", "foo", "foo/bar"].each do |path|
      basename = File.basename(path)
      assert_equal basename, URI.join("http://localhost", path).basename
      assert_equal basename, URI.join("http://localhost", path + "/").basename
    end
  end

  def test_query_param
    keys = ["", "[]", "[][x]", "[][y]", "[x][]", "[y][]"].map{|brack| "foo#{brack}" }
    values = ["a", "b", "c"]
    query = keys.product(values).map{|key, value| "#{key}=#{value}" }.join("&")
    uri = URI("http://localhost/?#{query}")

    keys.each do |key|
      expected = key.include?("[]") ? values : values.last
      assert_equal expected, uri.query_param(key)
    end

    assert_nil uri.query_param("miss")
  end

  def test_to_absolute_uri_with_absolute_uri
    uri = URI("http://localhost")
    assert_same uri, uri.to_absolute_uri
  end

  def test_to_absolute_uri_with_relative_uri
    uri = URI("/index.html")
    assert_raises { uri.to_absolute_uri }
  end

end

require "test_helper"

class StringTest < Minitest::Test

  def test_to_absolute_uri_with_absolute_uri
    string = "http://localhost"
    uri = string.to_absolute_uri
    assert_kind_of URI, uri
    assert_equal string, uri.to_s
  end

  def test_to_absolute_uri_with_relative_uri
    assert_raises { "/index.html".to_absolute_uri }
  end

end

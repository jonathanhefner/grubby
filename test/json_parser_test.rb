require "test_helper"

class GrubbyJsonParserTest < Minitest::Test

  def test_parse_on_initialize
    value = [{ "key1" => "val1", "key2" => "val2"}]
    result = Grubby::JsonParser.new(nil, nil, value.to_json, nil)
    assert_equal value, result.json
  end

  def test_parse_on_initialize_with_options
    Grubby::JsonParser.json_parse_options[:symbolize_names] = true

    value = [{ key1: "val1", key2: "val2"}]
    result = Grubby::JsonParser.new(nil, nil, value.to_json, nil)
    assert_equal value, result.json

    Grubby::JsonParser.json_parse_options[:symbolize_names] = false
  end

  def test_replace_options
    original = Grubby::JsonParser.json_parse_options

    replacement = { max_nesting: 9001 }
    Grubby::JsonParser.json_parse_options = replacement
    assert_equal replacement, Grubby::JsonParser.json_parse_options

    Grubby::JsonParser.json_parse_options = original
  end

end

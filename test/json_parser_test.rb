require "test_helper"

class GrubbyJsonParserTest < Minitest::Test

  def setup
    @original_json_parse_options = Grubby::JsonParser.json_parse_options.dup
  end

  def teardown
    Grubby::JsonParser.json_parse_options.replace(@original_json_parse_options)
  end

  def test_parse
    data = [{ "key1" => "val1", "key2" => "val2"}]
    parser = Grubby::JsonParser.new(nil, nil, data.to_json, nil)

    assert_equal data, parser.json
  end

  def test_parse_with_options
    Grubby::JsonParser.json_parse_options[:symbolize_names] = true
    data = [{ key1: "val1", key2: "val2"}]
    parser = Grubby::JsonParser.new(nil, nil, data.to_json, nil)

    assert_equal data, parser.json
  end

  def test_options_writer
    options = { max_nesting: 9001 }
    Grubby::JsonParser.json_parse_options = options

    assert_equal options, Grubby::JsonParser.json_parse_options
  end

end

require "test_helper"

class GrubbyJsonParserTest < Minitest::Test

  def setup
    @original_json_parse_options = Grubby::JsonParser.json_parse_options.dup
  end

  def teardown
    Grubby::JsonParser.json_parse_options.replace(@original_json_parse_options)
  end

  def test_initialize
    uri = URI("http://localhost")
    data = [{ "key1" => "val1" }, { "key2" => "val2" }]
    body = data.to_json
    code = "200"
    mech = Grubby.new
    parser = Grubby::JsonParser.new(uri, nil, body, code, mech)

    assert_equal uri, parser.uri
    assert_equal body, parser.body
    assert_equal data, parser.json
    assert_equal code, parser.code
    assert_same mech, parser.mech
  end

  def test_initialize_with_blanks
    [[], [nil] * 5, [nil, nil, "", nil, nil]].each do |args|
      parser = Grubby::JsonParser.new(*args) # does not raise
      assert_nil parser.json
    end
  end

  def test_initialize_with_json_parse_options
    Grubby::JsonParser.json_parse_options[:symbolize_names] = true
    data = [{ key1: "val1" }, { key2: "val2" }]
    parser = Grubby::JsonParser.new(nil, nil, data.to_json, nil, nil)

    assert_equal data, parser.json
  end

  def test_json_parse_options_writer
    options = { max_nesting: 9001 }
    Grubby::JsonParser.json_parse_options = options

    assert_equal options, Grubby::JsonParser.json_parse_options
  end

end

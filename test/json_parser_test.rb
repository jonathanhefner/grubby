require "test_helper"

class GrubbyJsonParserTest < Minitest::Test

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

  def test_json_parsing_is_safe
    require "json/add/complex"
    body = JSON.dump(Complex(0, 1))
    assert_instance_of Complex, JSON.load(body) # sanity check

    refute_instance_of Complex, Grubby::JsonParser.new(nil, nil, body).json
  end

end

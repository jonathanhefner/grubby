require "test_helper"

class NokogiriNodeTest < Minitest::Test

  def test_textbang_with_some_text
    assert_equal "some text", make_node.at("#some_text").text!
  end

  def test_textbang_with_no_text
    no_text = make_node.at("#no_text")
    assert_raises { no_text.text! }
  end


  private

  def make_node
    Nokogiri::XML(<<-XML)
      <root>
        <content id="some_text">
          some text
        </content>
        <content id="no_text">
          <nested />
          <nested></nested>
          <nested> </nested>
          <nested>
            <nested> </nested>
          </nested>
        </content>
      </root>
    XML
  end

end

require "test_helper"

class MechanizeFileTest < Mechanize::TestCase

  def test_content_hash
    content = "abcdef"
    assert_equal content.sha1, make_mechanize_file(content).content_hash
  end


  private

  def make_mechanize_file(content)
    Mechanize::File.new(nil, nil, content, nil)
  end

end

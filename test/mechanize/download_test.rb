require "test_helper"

class MechanizeDownloadTest < Mechanize::TestCase

  def test_content_hash
    content = "abcdef"
    assert_equal content.sha1, make_mechanize_download(content).content_hash
  end


  private

  def make_mechanize_download(content)
    Mechanize::Download.new(nil, nil, StringIO.new(content), nil)
  end

end

require "test_helper"

class MechanizeFileTest < Mechanize::TestCase

  def test_read_local
    Dir.mktmpdir do |dir|
      path = File.join(dir, "`this` & {that}.txt")
      content = "stuff\nmorestuff\n"
      File.write(path, content)
      mech_file = Mechanize::File.read_local(path)

      assert_instance_of Mechanize::File, mech_file
      assert_equal "file", mech_file.uri.scheme
      assert_equal path, CGI.unescape(mech_file.uri.path)
      assert_equal content, mech_file.content
      assert_equal "200", mech_file.code
    end
  end

  def test_content_hash
    content = "abcdef"
    mech_file = Mechanize::File.new(nil, nil, content, nil)
    assert_equal content.sha1, mech_file.content_hash
  end

end

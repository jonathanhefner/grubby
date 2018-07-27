require "test_helper"

class MechanizeParserTest < Mechanize::TestCase

  def test_save_to_sanity
    # sanity check that Mechanize includes the Mechanize::Parser module
    # and implements #save! in the relevant classes
    assert_includes Mechanize::File.included_modules, Mechanize::Parser
    assert_includes Mechanize::File.instance_methods, :save!
    assert_includes Mechanize::Download.included_modules, Mechanize::Parser
    assert_includes Mechanize::Download.instance_methods, :save!
    assert_includes Mechanize::Image.included_modules, Mechanize::Parser
    assert_includes Mechanize::Image.instance_methods, :save!
  end

  def test_save_to
    dir = "deeply/nested/dir/"
    html1 = "<h1>Hello</h1>"
    html2 = "<h2>Hello</h2>"

    in_tmpdir do
      path1 = html_page(html1).save_to(dir)
      assert_match %r"^#{dir}.+", path1
      assert_equal html1, File.read(path1)

      path2 = html_page(html2).save_to(dir)
      assert_match %r"^#{dir}.+", path2
      assert_equal html2, File.read(path2)
      refute_equal path1, path2
      assert_equal html1, File.read(path1)
    end
  end

  def test_save_to_bang
    dir = "deeply/nested/dir/"
    html1 = "<h1>Hello</h1>"
    html2 = "<h2>Hello</h2>"

    in_tmpdir do
      path1 = html_page(html1).save_to!(dir)
      assert_match %r"^#{dir}.+", path1
      assert_equal html1, File.read(path1)

      path2 = html_page(html2).save_to!(dir)
      assert_equal path1, path2
      assert_equal html2, File.read(path1)
    end
  end

end

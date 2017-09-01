require "test_helper"

class GrubbyTest < Mechanize::TestCase

  def test_that_it_has_a_version_number
    refute_nil ::Grubby::VERSION
  end

  def test_default_constructor
    assert_kind_of Mechanize, Grubby.new
  end

end

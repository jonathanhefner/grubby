require "test_helper"

class GrubbyTest < Mechanize::TestCase

  def test_that_it_has_a_version_number
    refute_nil ::Grubby::VERSION
  end

  def test_default_constructor
    assert_kind_of Mechanize, Grubby.new
  end

  def test_time_between_requests_with_number
    $sleep_last_amount = 0.0
    amount = 5.0

    grubby = Grubby.new
    grubby.time_between_requests = amount
    grubby.get("http://localhost")
    assert_equal 0.0, $sleep_last_amount
    grubby.get("http://localhost")
    assert_includes ((amount - 0.1)..amount), $sleep_last_amount
  end

  def test_time_between_requests_with_range
    $sleep_last_amount = 0.0
    min_amount = 5.0
    max_amount = 10.0

    grubby = Grubby.new
    grubby.time_between_requests = min_amount..max_amount
    grubby.get("http://localhost")
    assert_equal 0.0, $sleep_last_amount
    grubby.get("http://localhost")
    assert_includes ((min_amount - 0.1)..max_amount), $sleep_last_amount
  end

end

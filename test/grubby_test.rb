require "test_helper"

class GrubbyTest < Mechanize::TestCase

  class ::Grubby
    def stubbed_get(*args, &block)
      $stubbed_get_error_queue ||= []
      error = $stubbed_get_error_queue.shift
      raise error if error
      real_get(*args, &block)
    end

    alias_method :real_get, :get
    alias_method :get, :stubbed_get
  end

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

  def test_get_mirrored_with_first_successful
    mirror_uris = make_uris
    $stubbed_get_error_queue = []

    assert_equal mirror_uris.first, do_get_mirrored_result_uri(mirror_uris)
  end

  def test_get_mirrored_with_last_successful
    mirror_uris = make_uris
    $stubbed_get_error_queue = make_response_errors(mirror_uris[0...-1])

    assert_equal mirror_uris.last, do_get_mirrored_result_uri(mirror_uris)
  end

  def test_get_mirrored_with_none_successful
    mirror_uris = make_uris
    $stubbed_get_error_queue = make_response_errors(mirror_uris)

    assert_raises(Mechanize::ResponseCodeError) do
      do_get_mirrored_result_uri(mirror_uris)
    end
  end


  private

  def make_uris(count = 3)
    count.times.map{|i| URI("http://localhost/?#{i}") }
  end

  def make_response_errors(uris)
    uris.map do |u|
      Mechanize::ResponseCodeError.new(page(u, "text/html", "", 404))
    end
  end

  def do_get_mirrored_result_uri(mirror_uris)
    silence_logging do
      Grubby.new.get_mirrored(mirror_uris).uri
    end
  end

end

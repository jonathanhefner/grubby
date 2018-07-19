require "test_helper"

class FetchWithRetryTest < Mechanize::TestCase

  class ::Mechanize::HTTP::Agent
    def stubbed_fetch_without_retry(*args)
      $stubbed_fetch_error_queue ||= []
      error = $stubbed_fetch_error_queue.shift
      raise error if error
      real_fetch_without_retry(*args)
    end

    alias_method :real_fetch_without_retry, :fetch_without_retry
    alias_method :fetch_without_retry, :stubbed_fetch_without_retry
  end


  def test_fetch_works_normally
    $stubbed_fetch_error_queue = []
    assert_instance_of Mechanize::Page, do_fetch
  end

  def test_fetch_retries_upto_max
    max_retries = ::Mechanize::HTTP::Agent::MAX_CONNECTION_RESET_RETRIES
    $stubbed_fetch_error_queue = max_retries.times.map do
      Net::HTTP::Persistent::Error.new("too many connection resets")
    end

    out, err = capture_subprocess_io do
      assert_instance_of Mechanize::Page, do_fetch
    end
    assert_equal max_retries, (out + err).scan(/retry/i).length
  end

  def test_fetch_fails_after_max_retries
    max_retries = ::Mechanize::HTTP::Agent::MAX_CONNECTION_RESET_RETRIES
    $stubbed_fetch_error_queue = (max_retries + 1).times.map do
      Net::HTTP::Persistent::Error.new("too many connection resets")
    end

    out, err = capture_subprocess_io do
      assert_raises(Net::HTTP::Persistent::Error) { do_fetch }
    end
    assert_equal max_retries, (out + err).scan(/retry/i).length
  end

  def test_fetch_reraises_other_errors
    expected_error = RuntimeError.new("something else went wrong")
    $stubbed_fetch_error_queue = [expected_error]

    actual_error = assert_raises { do_fetch }
    assert_equal expected_error, actual_error
  end


  private

  def do_fetch
    Mechanize.new.get("http://localhost")
  end

end

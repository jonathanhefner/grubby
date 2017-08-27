require 'test_helper'

class LogTest < Minitest::Test

  def test_log_global_exists
    assert_kind_of Logger, $log
  end

  def test_log_global_logs
    out, err = capture_subprocess_io do
      $log.error('testing123')
    end

    assert_match 'testing123', (out + err)
  end

end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "grubby"

require "minitest/autorun"

require "mechanize/test_case"
# disable obnoxious coloring from "minitest/pride" forcibly included by "mechanize/test_case"
if Minitest.const_defined?("PrideIO")
  class << Minitest::PrideIO
    remove_method :pride?

    def pride?
      false
    end
  end
end


module Kernel

  def dont_sleep(amount)
    $sleep_calls ||= 0
    $sleep_calls += 1
    $sleep_total_amount ||= 0
    $sleep_total_amount += amount
    $sleep_last_amount = amount
  end

  alias_method :actually_sleep, :sleep
  alias_method :sleep, :dont_sleep

end


class Minitest::Test

  def silence_logging
    log_level = $log.level
    $log.level = Logger::Severity::FATAL
    begin
      result = yield
    ensure
      $log.level = log_level
    end
    result
  end

end

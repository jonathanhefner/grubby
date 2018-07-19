# This monkey patch attempts to fix the insidious "too many connection
# resets" bug described here: https://github.com/sparklemotion/mechanize/issues/123
#
# The code is taken and modified from this helpful blog article:
# http://scottwb.com/blog/2013/11/09/defeating-the-infamous-mechanize-too-many-connection-resets-bug/
class Mechanize::HTTP::Agent

  MAX_CONNECTION_RESET_RETRIES = 9
  IDEMPOTENT_HTTP_METHODS = [:get, :head, :options, :delete]

  # Replacement for +Mechanize::HTTP::Agent#fetch+.  When a "too many
  # connection resets" error is encountered, this method retries the
  # request (upto {MAX_CONNECTION_RESET_RETRIES} times).
  def fetch_with_retry(uri, http_method = :get, headers = {}, params = [], referer = current_page, redirects = 0)
    retry_count = 0
    begin
      fetch_without_retry(uri, http_method, headers, params, referer, redirects)
    rescue Net::HTTP::Persistent::Error => e
      # raise if different type of error
      raise unless e.message.include?("too many connection resets")
      # raise if non-idempotent http method
      raise unless IDEMPOTENT_HTTP_METHODS.include?(http_method)
      # raise if we've tried too many times
      raise if retry_count >= MAX_CONNECTION_RESET_RETRIES

      # otherwise, shutdown the persistent HTTP connection and try again
      retry_count += 1
      $log.warn("Possible connection reset bug.  Retry(#{retry_count}) #{http_method.to_s.upcase} #{uri}")
      sleep(retry_count) # incremental backoff to allow server to self-correct
      retry
    end
  end

  alias_method :fetch_without_retry, :fetch
  alias_method :fetch, :fetch_with_retry

end

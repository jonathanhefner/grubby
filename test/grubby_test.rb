require "test_helper"

class GrubbyTest < Mechanize::TestCase

  def test_that_it_has_a_version_number
    refute_nil Grubby::VERSION
  end

  def test_default_constructor
    assert_kind_of Mechanize, Grubby.new
  end

  def test_global_default_instance
    assert_instance_of Grubby, $grubby
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

  def test_time_between_requests_begins_after_request_finishes
    grubby = Grubby.new
    grubby.time_between_requests = 1.0
    # use content-encoding hook so that a time recorded by a pre-connect
    # hook will be disregarded, while a time recorded by a post-connect
    # hook will not
    grubby.content_encoding_hooks << Proc.new{ grubby.send(:mark_last_request_time, nil) }

    grubby.get("http://localhost")
    $sleep_last_amount = 0.0
    grubby.get("http://localhost")
    assert_operator $sleep_last_amount, :>, 0.0
  end

  def test_sleep_between_requests_after_redirect
    $sleep_calls = 0
    redirect_url = "http://localhost/redirect"
    grubby = Grubby.new

    actual_url = grubby.get(redirect_url).uri.to_s
    refute_equal redirect_url, actual_url # sanity check
    grubby.get(redirect_url)
    assert_equal 1, $sleep_calls
  end

  def test_ok_predicate_with_success_code
    assert Grubby.new.ok?(make_uris(1).first)
  end

  def test_ok_predicate_with_error_code
    refute Grubby.new.ok?(make_uris(1, "500").first)
  end

  def test_get_mirrored_with_first_successful
    uris = make_uris(2)

    assert_equal uris.first, get_mirrored_resultant_uri(uris)
  end

  def test_get_mirrored_with_last_successful
    uris = make_uris(2, "404") + make_uris(1)

    assert_equal uris.last, get_mirrored_resultant_uri(uris)
  end

  def test_get_mirrored_with_none_successful
    uris = make_uris(2, "404")

    assert_raises(Mechanize::ResponseCodeError) do
      get_mirrored_resultant_uri(uris)
    end
  end

  def test_singleton_with_different_pages
    uris = make_uris(2)
    uris.last.path = "/form_test.html"

    assert_equal uris, singleton_resultant_uris(uris)
  end

  def test_singleton_with_same_url
    uris = make_uris(1) * 2

    assert_equal uris.uniq, singleton_resultant_uris(uris)
  end

  def test_singleton_with_same_page_content
    uris = make_uris(2)

    assert_equal uris.take(1), singleton_resultant_uris(uris)
  end

  def test_singleton_with_different_purposes
    purposes = 2.times.map{|i| "purpose #{i}" }
    uris = make_uris(1) * purposes.length

    assert_equal uris, singleton_resultant_uris(uris.zip(purposes))
  end

  def test_singleton_journal
    uris = make_uris(2)

    in_tmpdir do
      refute_empty singleton_resultant_uris(uris, Grubby.new("journal.txt"))
      assert_empty singleton_resultant_uris(uris, Grubby.new("journal.txt"))
    end
  end

  def test_singleton_journal_with_different_pages
    uris = make_uris(2)
    uris.last.path = "/form_test.html"

    in_tmpdir do
      refute_empty singleton_resultant_uris(uris.take(1), Grubby.new("journal.txt"))
      refute_empty singleton_resultant_uris(uris.drop(1), Grubby.new("journal.txt"))
    end
  end

  def test_singleton_journal_with_different_purposes
    purposes = 2.times.map{|i| "purpose #{i}" }
    uris = make_uris(1) * purposes.length
    requests = uris.zip(purposes)

    in_tmpdir do
      refute_empty singleton_resultant_uris(requests, Grubby.new("journal.txt"))
      assert_empty singleton_resultant_uris(requests, Grubby.new("journal.txt"))
    end
  end

  def test_journal_initializer
    in_tmpdir do
      assert_equal Pathname.new("expected"), Grubby.new("expected").journal
    end
  end

  def test_journal_attr
    uris = make_uris(2)
    journal_a = Pathname.new("a")
    journal_b = Pathname.new("b")

    in_tmpdir do
      grubby = Grubby.new

      grubby.journal = journal_a.to_s
      assert_equal journal_a, grubby.journal
      refute_empty singleton_resultant_uris(uris, grubby)

      grubby.journal = journal_b
      assert_equal journal_b, grubby.journal
      refute_empty singleton_resultant_uris(uris, grubby)

      grubby.journal = journal_a
      assert_empty singleton_resultant_uris(uris, grubby)

      grubby.journal = nil
      assert_nil grubby.journal
      refute_empty singleton_resultant_uris(uris, grubby)
    end
  end

  def test_json_pluggable_parser
    grubby = Grubby.new
    parser = grubby.get("http://localhost/response_code?code=200&ct=application/json")

    assert_instance_of Grubby::JsonParser, parser
    assert_same grubby, parser.mech
  end


  private

  def make_uris(count, response_code = "200")
    count.times.map do |i|
      URI("http://localhost/response_code?code=#{response_code}&i=#{i}")
    end
  end

  def get_mirrored_resultant_uri(uris)
    silence_logging do
      Grubby.new.get_mirrored(uris).uri
    end
  end

  def singleton_resultant_uris(requests, grubby = Grubby.new)
    resultant_uris = []

    silence_logging do
      requests.each do |args|
        previous_count = resultant_uris.length
        visited = grubby.singleton(*args){|page| resultant_uris << page.uri }
        assert_equal (resultant_uris.length > previous_count), !!visited
      end
    end

    resultant_uris
  end

end

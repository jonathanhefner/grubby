require "test_helper"

class GrubbyTest < Mechanize::TestCase

  def test_that_it_has_a_version_number
    refute_nil Grubby::VERSION
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

  def test_journal_attr
    in_tmpdir do
      assert_equal Pathname.new("expected"), Grubby.new("expected").journal
    end
  end

  def test_json_pluggable_parser
    grubby = Grubby.new

    assert_equal Grubby::JsonParser, grubby.pluggable_parser["application/json"]
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

require "test_helper"

class MechanizeLinkTest < Mechanize::TestCase

  def test_to_absolute_uri_with_absolute_href
    href = "http://localhost"
    uri = make_link(href).to_absolute_uri
    assert_kind_of URI, uri
    assert_equal href, uri.to_s
  end

  def test_to_absolute_uri_with_relative_href
    href = "/index.html"
    uri = make_link(href).to_absolute_uri
    assert_kind_of URI, uri
    assert uri.absolute?
    assert uri.to_s.end_with?(href)
  end

  def test_to_absolute_uri_with_nil_href
    uri = make_link(nil).to_absolute_uri
    assert_kind_of URI, uri
    assert uri.absolute?
  end


  private

  def make_link(href)
    page = html_page(<<-HTML)
      <html>
      <body>
        <a #{href && "href=\"#{href}\""}>link</a>
      </body>
      </html>
    HTML

    page.links.first
  end

end

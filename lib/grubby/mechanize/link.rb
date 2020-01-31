class Mechanize::Page::Link

  # Returns the URI represented by the Link, in absolute form.  If the
  # href attribute of the Link is expressed in relative form, the URI is
  # converted to absolute form using the Link's +page.uri+.  Raises an
  # exception if the URI cannot be converted to absolute form.
  #
  # @return [URI]
  # @raise [RuntimeError]
  #   if the URI cannot be converted to absolute form
  def to_absolute_uri
    # Via the W3 spec[1]: "If the a element has no href attribute, then
    # the element represents a placeholder for where a link might
    # otherwise have been placed, if it had been relevant, consisting of
    # just the element's contents."  So, we assume a link with no href
    # attribute (i.e. `uri == nil`) should be treated the same as an
    # intra-page link.
    #
    # [1]: https://www.w3.org/TR/2016/REC-html51-20161101/textlevel-semantics.html#the-a-element
    URI.join(self.page.uri, self.uri || "#").to_absolute_uri
  end

end

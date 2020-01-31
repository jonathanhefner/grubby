module URI

  # Returns the basename of the URI's +path+, a la +File.basename+.
  #
  # @example
  #   URI("https://example.com/foo/bar").basename  # == "bar"
  #   URI("https://example.com/foo").basename      # == "foo"
  #   URI("https://example.com/").basename         # == ""
  #
  # @return [String]
  def basename
    self.path == "/" ? "" : ::File.basename(self.path)
  end

  # Returns the value of the specified query param in the URI's query
  # string.  The specified +name+ must be *exactly* as it appears in the
  # query string, and support for complex nested values is limited.
  # (See +CGI.parse+ for parsing behavior.)  If +name+ contains +"[]"+,
  # all occurrences of the query param are returned as an Array.
  # Otherwise, only the last occurrence is returned.
  #
  # @example
  #   URI("https://example.com/?foo=a").query_param("foo")  # == "a"
  #
  #   URI("https://example.com/?foo=a&foo=b").query_param("foo")    # == "b"
  #   URI("https://example.com/?foo=a&foo=b").query_param("foo[]")  # == nil
  #
  #   URI("https://example.com/?foo[]=a&foo[]=b").query_param("foo")    # == nil
  #   URI("https://example.com/?foo[]=a&foo[]=b").query_param("foo[]")  # == ["a", "b"]
  #
  #   URI("https://example.com/?foo[][x]=a&foo[][y]=b").query_param("foo[]")     # == nil
  #   URI("https://example.com/?foo[][x]=a&foo[][y]=b").query_param("foo[][x]")  # == ["a"]
  #
  # @param name [String]
  # @return [String, Array<String>, nil]
  def query_param(name)
    values = CGI.parse(self.query)[name] if self.query
    (values.nil? || name.include?("[]")) ? values : values.last
  end

  # Raises an exception if the URI is not +absolute?+.  Otherwise,
  # returns the URI.
  #
  # @return [self]
  # @raise [RuntimeError]
  #   if the URI is not +absolute?+
  def to_absolute_uri
    raise "URI is not absolute: #{self}" unless self.absolute?
    self
  end

end

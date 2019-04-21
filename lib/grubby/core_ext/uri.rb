module URI

  # Returns the basename of the URI's +path+, a la +File.basename+.
  #
  # @example
  #   URI("http://example.com/foo/bar").basename  # == "bar"
  #   URI("http://example.com/foo").basename      # == "foo"
  #   URI("http://example.com/").basename         # == ""
  #
  # @return [String]
  def basename
    self.path == "/" ? "" : ::File.basename(self.path)
  end

  # Returns the value of the specified param in the URI's +query+.
  # The specified param name must be exactly as it appears in the query
  # string, and support for complex nested values is limited.  (See
  # +CGI.parse+ for parsing behavior.)  If the param name includes a
  # +"[]"+, the result will be an array of all occurrences of that param
  # in the query string.  Otherwise, the result will be the last
  # occurrence of that param in the query string.
  #
  # @example
  #   URI("http://example.com/?foo=a").query_param("foo")          # == "a"
  #
  #   URI("http://example.com/?foo=a&foo=b").query_param("foo")    # == "b"
  #   URI("http://example.com/?foo=a&foo=b").query_param("foo[]")  # == nil
  #
  #   URI("http://example.com/?foo[]=a&foo[]=b").query_param("foo")    # == nil
  #   URI("http://example.com/?foo[]=a&foo[]=b").query_param("foo[]")  # == ["a", "b"]
  #
  #   URI("http://example.com/?foo[][x]=a&foo[][y]=b").query_param("foo[]")     # == nil
  #   URI("http://example.com/?foo[][x]=a&foo[][y]=b").query_param("foo[][x]")  # == ["a"]
  #
  # @return [String, nil]
  # @return [Array<String>, nil]
  #   if +name+ contains +"[]"+
  def query_param(name)
    values = CGI.parse(self.query)[name.to_s]
    (values.nil? || name.include?("[]")) ? values : values.last
  end

  # Raises an exception if the URI is not +absolute?+.
  #
  # @return [self]
  # @raise [RuntimeError] if the URI is not +absolute?+
  def to_absolute_uri
    raise "URI is not absolute: #{self}" unless self.absolute?
    self
  end

end

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
    self.path == "/" ? "" : File.basename(self.path)
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

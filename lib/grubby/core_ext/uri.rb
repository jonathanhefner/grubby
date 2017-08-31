module URI

  # Raises an exception if the URI is not +absolute?+.
  #
  # @return [self]
  # @raise [RuntimeError] if the URI is not +absolute?+
  def to_absolute_uri
    raise "URI is not absolute: #{self}" unless self.absolute?
    self
  end

end

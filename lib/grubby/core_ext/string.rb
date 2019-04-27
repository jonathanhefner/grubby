class String

  # Constructs a URI from the String.  Raises an exception if the String
  # does not denote an absolute URI.
  #
  # @return [URI]
  # @raise [RuntimeError]
  #   if the String does not denote an absolute URI
  def to_absolute_uri
    URI(self).to_absolute_uri
  end

end

class Nokogiri::XML::Node

  # Equivalent to +.text.strip+, but raises an error if the result is an
  # empty string.
  #
  # @return [String]
  # @raise [RuntimeError] if result is an empty string
  def text!
    result = self.text.strip
    raise "No text in:\n#{self.to_html}" if result.empty?
    result
  end

end

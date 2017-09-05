class Mechanize::Page

  # @!method search!(*queries)
  # See {::Nokogiri::XML::Searchable#search!}.
  #
  # @param queries [Array<String>]
  # @return [Array<Nokogiri::XML::Element>]
  def_delegators :parser, :search!

end

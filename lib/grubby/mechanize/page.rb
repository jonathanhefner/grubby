class Mechanize::Page

  # @!method search!(*queries)
  # See Ryoba's +Nokogiri::XML::Searchable#search!+.
  #
  # @param queries [Array<String>]
  # @return [Nokogiri::XML::NodeSet]
  # @raise [Ryoba::Error]
  #   if all queries yield no results
  def_delegators :parser, :search!

  # @!method at!(*queries)
  # See Ryoba's +Nokogiri::XML::Searchable#at!+.
  #
  # @param queries [Array<String>]
  # @return [Nokogiri::XML::Element]
  # @raise [Ryoba::Error]
  #   if all queries yield no results
  def_delegators :parser, :at!

end

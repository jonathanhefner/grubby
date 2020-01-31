class Mechanize::Page

  # @!method search!(*queries)
  # See ryoba's {https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:search%21
  # +Nokogiri::XML::Searchable#search!+}.
  #
  # @param queries [Array<String>]
  # @return [Nokogiri::XML::NodeSet]
  # @raise [Ryoba::Error]
  #   if all queries yield no results
  def_delegators :parser, :search!

  # @!method at!(*queries)
  # See ryoba's {https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:at%21
  # +Nokogiri::XML::Searchable#at!+}.
  #
  # @param queries [Array<String>]
  # @return [Nokogiri::XML::Element]
  # @raise [Ryoba::Error]
  #   if all queries yield no results
  def_delegators :parser, :at!

end

module Nokogiri::XML::Searchable

  # Searches the node using the given XPath or CSS queries, and returns
  # the results.  Raises an exception if there are no results.  See also
  # +#search+.
  #
  # @param queries [Array<String>]
  # @return [Array<Nokogiri::XML::Element>]
  # @raise [RuntimeError] if queries yield no results
  def search!(*queries)
    results = search(*queries)
    raise "No elements matching #{queries.map(&:inspect).join(" OR ")}" if results.empty?
    results
  end

end

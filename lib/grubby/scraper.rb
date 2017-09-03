class Grubby::Scraper

  class Error < RuntimeError
  end

  # Defines an attribute reader method named by +field+.  During
  # +initialize+, the given block is called, and the attribute is set to
  # the block's return value.  By default, if the block's return value
  # is nil, an exception will be raised.  To prevent this behavior, set
  # +optional+ to true.
  #
  # @param field [Symbol, String]
  #   name of the scraped value
  # @param optional [Boolean]
  #   whether to permit a nil scraped value
  # @yield []
  #   scrapes the value
  # @yieldreturn [Object]
  #   scraped value
  def self.scrapes(field, optional: false, &block)
    field = field.to_sym
    self.fields << field

    define_method(field) do
      return @scraped[field] if @scraped.key?(field)

      unless @errors.key?(field)
        begin
          value = instance_eval(&block)
          if value.nil?
            raise "`#{field}` cannot be nil" unless optional
            $log.debug("Scraped nil value for #{self.class}##{field}")
          end
          @scraped[field] = value
        rescue RuntimeError => e
          @errors[field] = e
        end
      end

      raise "`#{field}` raised a #{@errors[field].class}" if @errors.key?(field)

      @scraped[field]
    end
  end

  # @return [Array<Symbol>]
  #   The names of all scraped values, as defined by {scrapes}.
  def self.fields
    @fields ||= []
  end

  # @return [Object]
  #   The source being scraped.  Typically a Mechanize pluggable parser
  #   such as +Mechanize::Page+.
  attr_reader :source

  # @param source
  # @raise [Grubby::Scraper::Error]
  #   if any scraped values result in error
  def initialize(source)
    @source = source
    @scraped = {}
    @errors = {}

    self.class.fields.each do |field|
      begin
        self.send(field)
      rescue RuntimeError
      end
    end

    unless @errors.empty?
      listing = @errors.map do |field, error|
        error_class = " (#{error.class})" unless error.class == RuntimeError
        error_trace = error.backtrace.join("\n").indent(2)
        "* #{field} -- #{error.message}#{error_class}\n#{error_trace}"
      end
      raise Error.new("Failed to scrape the following fields:\n#{listing.join("\n")}")
    end
  end

  # Returns the scraped value named by +field+.
  #
  # @param field [Symbol, String]
  # @return [Object]
  # @raise [RuntimeError]
  #   if +field+ is not a valid name
  def [](field)
    @scraped.fetch(field.to_sym)
  end

  # Returns all scraped values as a Hash.
  #
  # @return [Hash<Symbol, Object>]
  def to_h
    @scraped.dup
  end

end

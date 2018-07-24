class Grubby::Scraper

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
      raise "#{self.class}#initialize does not invoke `super`" unless defined?(@scraped)
      return @scraped[field] if @scraped.key?(field)

      unless @errors[field]
        begin
          value = instance_eval(&block)
          if value.nil?
            raise FieldValueRequiredError.new(field) unless optional
            $log.debug("#{self.class}##{field} is nil")
          end
          @scraped[field] = value
        rescue RuntimeError, IndexError => e
          @errors[field] = e
        end
      end

      raise FieldScrapeFailedError.new(field, @errors[field]) if @errors[field]

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

  # @return [Hash<Symbol, StandardError>]
  #   Hash of errors raised by blocks passed to {scrapes}.  If
  #   {initialize} does not raise +Grubby::Scraper::Error+, this Hash
  #   will be empty.
  attr_reader :errors

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
      rescue FieldScrapeFailedError
      end
    end

    raise Error.new(self) unless @errors.empty?
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

  class Error < RuntimeError
    BACKTRACE_CLEANER = ActiveSupport::BacktraceCleaner.new.tap do |cleaner|
      cleaner.add_silencer do |line|
        line.include?(__dir__) && line.include?("scraper.rb:")
      end
    end

    # @return [Grubby::Scraper]
    #   The Scraper that raised this error.
    attr_accessor :scraper

    def initialize(scraper)
      self.scraper = scraper

      listing = scraper.errors.
        reject{|field, error| error.is_a?(FieldScrapeFailedError) }.
        map do |field, error|
          "* `#{field}` (#{error.class})\n" +
            error.message.indent(2) + "\n\n" +
            BACKTRACE_CLEANER.clean(error.backtrace).join("\n").indent(4) + "\n"
        end.
        join("\n")

      super("Failed to scrape the following fields:\n#{listing}")
    end
  end

  class FieldScrapeFailedError < RuntimeError
    def initialize(field, field_error)
      super("`#{field}` raised #{field_error.class}")
    end
  end

  class FieldValueRequiredError < RuntimeError
    def initialize(field)
      super("`#{field}` is nil but is not marked as optional")
    end
  end

end

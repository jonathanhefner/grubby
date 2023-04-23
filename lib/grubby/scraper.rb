class Grubby::Scraper

  # Defines an attribute reader method named by +field+.  During
  # {initialize}, the given block is called, and the attribute is set to
  # the block's return value.
  #
  # By default, raises an exception if the block's return value is nil.
  # To prevent this behavior, set the +:optional+ option to true.
  # Alternatively, the block can be conditionally evaluated, based on
  # another method's return value, using the +:if+ or +:unless+ options.
  #
  # @example Default behavior
  #   class GreetingScraper < Grubby::Scraper
  #     scrapes(:name) do
  #       source[/Hello (\w+)/, 1]
  #     end
  #   end
  #
  #   scraper = GreetingScraper.new("Hello World!")
  #   scraper.name  # == "World"
  #
  #   scraper = GreetingScraper.new("Hello!")  # raises Grubby::Scraper::Error
  #
  # @example Optional scraped value
  #   class GreetingScraper < Grubby::Scraper
  #     scrapes(:name, optional: true) do
  #       source[/Hello (\w+)/, 1]
  #     end
  #   end
  #
  #   scraper = GreetingScraper.new("Hello World!")
  #   scraper.name  # == "World"
  #
  #   scraper = GreetingScraper.new("Hello!")
  #   scraper.name  # == nil
  #
  # @example Conditional scraped value
  #   class GreetingScraper < Grubby::Scraper
  #     def hello?
  #       source.start_with?("Hello ")
  #     end
  #
  #     scrapes(:name, if: :hello?) do
  #       source[/Hello (\w+)/, 1]
  #     end
  #   end
  #
  #   scraper = GreetingScraper.new("Hello World!")
  #   scraper.name  # == "World"
  #
  #   scraper = GreetingScraper.new("Hello!")  # raises Grubby::Scraper::Error
  #
  #   scraper = GreetingScraper.new("How are you?")
  #   scraper.name  # == nil
  #
  # @param field [Symbol, String]
  # @param options [Hash]
  # @option options :optional [Boolean] (false)
  #   Whether the block should be allowed to return a nil value
  # @option options :if [Symbol] (nil)
  #   Name of predicate method that determines if the block should be
  #   evaluated
  # @option options :unless [Symbol] (nil)
  #   Name of predicate method that determines if the block should not
  #   be evaluated
  # @yieldreturn [Object]
  # @return [void]
  def self.scrapes(field, **options, &block)
    field = field.to_sym
    (self.fields << field).uniq!

    define_method(field) do
      raise "#{self.class}#initialize does not invoke `super`" unless defined?(@scraped)

      if !@scraped.key?(field) && !@errors.key?(field)
        begin
          skip = (options[:if] && !self.send(options[:if])) ||
            (options[:unless] && self.send(options[:unless]))

          if skip
            @scraped[field] = nil
          else
            @scraped[field] = instance_eval(&block)
            if @scraped[field].nil?
              raise FieldValueRequiredError.new(field) unless options[:optional]
              Grubby.logger.debug("#{self.class}##{field} is nil")
            end
          end
        rescue RuntimeError, IndexError => e
          @errors[field] = e
        end
      end

      if @errors.key?(field)
        raise FieldScrapeFailedError.new(field, @errors[field])
      else
        @scraped[field]
      end
    end
  end

  # Fields defined via {scrapes}.
  #
  # @return [Array<Symbol>]
  def self.fields
    @fields ||= self == Grubby::Scraper ? [] : self.superclass.fields.dup
  end

  # Instantiates the Scraper class with the resource indicated by +url+.
  # This method acts as a default factory method, and provides a
  # standard interface for overrides.
  #
  # @example Default factory method
  #   class PostPageScraper < Grubby::PageScraper
  #     # ...
  #   end
  #
  #   PostPageScraper.scrape("https://example.com/posts/42")
  #     # == PostPageScraper.new($grubby.get("https://example.com/posts/42"))
  #
  # @example Override factory method
  #   class PostApiScraper < Grubby::JsonScraper
  #     # ...
  #
  #     def self.scrape(url, agent = $grubby)
  #       api_url = url.to_s.sub(%r"//example.com/(.+)", '//api.example.com/\1.json')
  #       super(api_url, agent)
  #     end
  #   end
  #
  #   PostApiScraper.scrape("https://example.com/posts/42")
  #     # == PostApiScraper.new($grubby.get("https://api.example.com/posts/42.json"))
  #
  # @param url [String, URI]
  # @param agent [Mechanize]
  # @return [Grubby::Scraper]
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def self.scrape(url, agent = $grubby)
    self.new(agent.get(url))
  end

  # Iterates a series of pages, starting at +start+.  The Scraper class
  # is instantiated with each page, and each Scraper instance is passed
  # to the given block.  Subsequent pages in the series are determined
  # by invoking the +next_method+ method on each Scraper instance.
  #
  # Iteration stops when the +next_method+ method returns falsy.  If the
  # +next_method+ method returns a String or URI, that value will be
  # treated as the URL of the next page.  Otherwise that value will be
  # treated as the page itself.
  #
  # @example Iterate from page object
  #   class PostsIndexScraper < Grubby::PageScraper
  #     def next
  #       page.link_with(text: "Next >")&.click
  #     end
  #   end
  #
  #   PostsIndexScraper.each("https://example.com/posts?page=1") do |scraper|
  #     scraper.page.uri.query  # == "page=1", "page=2", "page=3", ...
  #   end
  #
  # @example Iterate from URI
  #   class PostsIndexScraper < Grubby::PageScraper
  #     def next
  #       page.link_with(text: "Next >")&.to_absolute_uri
  #     end
  #   end
  #
  #   PostsIndexScraper.each("https://example.com/posts?page=1") do |scraper|
  #     scraper.page.uri.query  # == "page=1", "page=2", "page=3", ...
  #   end
  #
  # @example Specifying the iteration method
  #   class PostsIndexScraper < Grubby::PageScraper
  #     scrapes(:next_uri, optional: true) do
  #       page.link_with(text: "Next >")&.to_absolute_uri
  #     end
  #   end
  #
  #   PostsIndexScraper.each("https://example.com/posts?page=1", next_method: :next_uri) do |scraper|
  #     scraper.page.uri.query  # == "page=1", "page=2", "page=3", ...
  #   end
  #
  # @param start [String, URI, Mechanize::Page, Mechanize::File]
  # @param agent [Mechanize]
  # @param next_method [Symbol]
  # @yieldparam scraper [Grubby::Scraper]
  # @return [void]
  # @raise [NoMethodError]
  #   if the Scraper class does not define the method indicated by
  #   +next_method+
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
  def self.each(start, agent = $grubby, next_method: :next)
    unless self.method_defined?(next_method)
      raise NoMethodError.new(nil, next_method), "#{self} does not define `#{next_method}`"
    end

    return to_enum(:each, start, agent, next_method: next_method) unless block_given?

    current = start
    while current
      current = agent.get(current) if current.is_a?(String) || current.is_a?(URI)
      scraper = self.new(current)
      yield scraper
      current = scraper.send(next_method)
    end
  end

  # The object being scraped.  Typically an instance of a Mechanize
  # pluggable parser such as +Mechanize::Page+.
  #
  # @return [Object]
  attr_reader :source

  # Collected errors raised during {initialize} by {Scraper.scrapes}
  # blocks, indexed by field name.  This Hash will be empty if
  # {initialize} did not raise a +Grubby::Scraper::Error+.
  #
  # @return [Hash{Symbol => StandardError}]
  attr_reader :errors

  # @param source
  # @raise [Grubby::Scraper::Error]
  #   if any {Scraper.scrapes} blocks fail
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
  # @return [Hash{Symbol => Object}]
  def to_h
    @scraped.dup
  end

  class Error < RuntimeError
    # The Scraper that raised this Error.
    #
    # @return [Grubby::Scraper]
    attr_accessor :scraper

    # @!visibility private
    def initialize(scraper)
      self.scraper = scraper

      listing = scraper.errors.
        reject{|field, error| error.is_a?(FieldScrapeFailedError) }.
        map do |field, error|
          "* `#{field}` (#{error.class})\n" +
            error.message.gsub(/^/, "  ") + "\n\n" +
            clean_backtrace(error.backtrace).join("\n").gsub(/^/, "    ") + "\n"
        end.
        join("\n")

      super("Failed to scrape the following fields:\n#{listing}")
    end

    private
      def clean_backtrace(backtrace)
        backtrace.reject do |line|
          line.start_with?(__dir__) && line.include?("scraper.rb:")
        end
      end
  end

  # @!visibility private
  class FieldScrapeFailedError < RuntimeError
    def initialize(field, field_error)
      super("`#{field}` raised #{field_error.class}")
    end
  end

  # @!visibility private
  class FieldValueRequiredError < RuntimeError
    def initialize(field)
      super("`#{field}` is nil but is not marked as optional")
    end
  end

end

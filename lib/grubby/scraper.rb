class Grubby::Scraper

  # Defines an attribute reader method named by +field+.  During
  # +initialize+, the given block is called, and the attribute is set to
  # the block's return value.
  #
  # By default, if the block's return value is nil, an exception will be
  # raised.  To prevent this behavior, specify +optional: true+.
  #
  # The block may also be evaluated conditionally, based on another
  # method's return value, using the +:if+ or +:unless+ options.
  #
  # @example
  #   class GreetingScraper < Grubby::Scraper
  #     scrapes(:salutation) do
  #       source[/\A(hello|good morning)\b/i]
  #     end
  #
  #     scrapes(:recipient, optional: true) do
  #       source[/\A#{salutation} ([a-z ]+)/i, 1]
  #     end
  #   end
  #
  #   scraper = GreetingScraper.new("Hello World!")
  #   scraper.salutation  # == "Hello"
  #   scraper.recipient   # == "World"
  #
  #   scraper = GreetingScraper.new("Good morning!")
  #   scraper.salutation  # == "Good morning"
  #   scraper.recipient   # == nil
  #
  #   scraper = GreetingScraper.new("Hey!")  # raises Grubby::Scraper::Error
  #
  # @example
  #   class EmbeddedUrlScraper < Grubby::Scraper
  #     scrapes(:url, optional: true){ source[%r"\bhttps?://\S+"] }
  #
  #     scrapes(:domain, if: :url){ url[%r"://([^/]+)/", 1] }
  #   end
  #
  #   scraper = EmbeddedUrlScraper.new("visit https://example.com/foo for details")
  #   scraper.url     # == "https://example.com/foo"
  #   scraper.domain  # == "example.com"
  #
  #   scraper = EmbeddedUrlScraper.new("visit our website for details")
  #   scraper.url     # == nil
  #   scraper.domain  # == nil
  #
  # @param field [Symbol, String]
  # @param options [Hash]
  # @option options :optional [Boolean]
  # @option options :if [Symbol]
  # @option options :unless [Symbol]
  # @yield []
  # @yieldreturn [Object]
  # @return [void]
  def self.scrapes(field, **options, &block)
    field = field.to_sym
    self.fields << field

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
              $log.debug("#{self.class}##{field} is nil")
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

  # Fields defined by {scrapes}.
  #
  # @return [Array<Symbol>]
  def self.fields
    @fields ||= self == Grubby::Scraper ? [] : self.superclass.fields.dup
  end

  # Instantiates the Scraper class with the resource specified by +url+.
  # This method acts as a default factory method, and provides a
  # standard interface for specialized overrides.
  #
  # @example Default factory method
  #   class PostPageScraper < Grubby::PageScraper
  #     # ...
  #   end
  #
  #   PostPageScraper.scrape("https://example.com/posts/42")
  #     # == PostPageScraper.new($grubby.get("https://example.com/posts/42"))
  #
  # @example Specialized factory method
  #   class PostApiScraper < Grubby::JsonScraper
  #     # ...
  #
  #     def self.scrapes(url, agent = $grubby)
  #       api_url = url.sub(%r"//example.com/(.+)", '//api.example.com/\1.json')
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
  def self.scrape(url, agent = $grubby)
    self.new(agent.get(url))
  end

  # Iterates a series of pages, starting at +start_url+.  For each page,
  # the Scraper class is instantiated and passed to the given block.
  # Subsequent pages in the series are determined by invoking
  # +next_method+ on each previous scraper instance.
  #
  # Iteration stops when the +next_method+ method returns nil.  If the
  # +next_method+ method returns a String or URI, that value will be
  # treated as the URL of the next page.  Otherwise that value will be
  # treated as the page itself.
  #
  # @example
  #   class PostsIndexScraper < Grubby::PageScraper
  #     scrapes(:page_param){ page.uri.query_param("page") }
  #
  #     def next
  #       page.link_with(text: "Next >")&.click
  #     end
  #   end
  #
  #   PostsIndexScraper.each("https://example.com/posts?page=1") do |scraper|
  #     scraper.page_param  # == "1", "2", "3", ...
  #   end
  #
  # @example
  #   class PostsIndexScraper < Grubby::PageScraper
  #     scrapes(:page_param){ page.uri.query_param("page") }
  #
  #     scrapes(:next_uri, optional: true) do
  #       page.link_with(text: "Next >")&.to_absolute_uri
  #     end
  #   end
  #
  #   PostsIndexScraper.each("https://example.com/posts?page=1", next_method: :next_uri) do |scraper|
  #     scraper.page_param  # == "1", "2", "3", ...
  #   end
  #
  # @param start_url [String, URI]
  # @param agent [Mechanize]
  # @param next_method [Symbol]
  # @yield [scraper]
  # @yieldparam scraper [Grubby::Scraper]
  # @return [void]
  # @raise [NoMethodError]
  #   if Scraper class does not implement +next_method+
  def self.each(start_url, agent = $grubby, next_method: :next)
    unless self.method_defined?(next_method)
      raise NoMethodError.new(nil, next_method), "#{self} does not define `#{next_method}`"
    end

    return to_enum(:each, start_url, agent, next_method: next_method) unless block_given?

    current = start_url
    while current
      current = agent.get(current) if current.is_a?(String) || current.is_a?(URI)
      scraper = self.new(current)
      yield scraper
      current = scraper.send(next_method)
    end
  end

  # The object being scraped.  Typically a Mechanize pluggable parser
  # such as +Mechanize::Page+.
  #
  # @return [Object]
  attr_reader :source

  # Collected errors raised during {initialize} by blocks passed to
  # {scrapes}, indexed by field name.  If {initialize} did not raise
  # +Grubby::Scraper::Error+, this Hash will be empty.
  #
  # @return [Hash<Symbol, StandardError>]
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

  # @!visibility private
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

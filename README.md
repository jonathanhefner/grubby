# grubby

[Fail-fast] web scraping.  *grubby* adds a layer of utility and
error-checking atop the marvelous [Mechanize gem].  See API summary
below, or browse the [full documentation].

[Fail-fast]: https://en.wikipedia.org/wiki/Fail-fast
[Mechanize gem]: https://rubygems.org/gems/mechanize
[full documentation]: http://www.rubydoc.info/gems/grubby/


## Examples

The following example scrapes the [Hacker News] front page:

```ruby
require "grubby"

class HackerNews < Grubby::PageScraper

  scrapes(:items) do
    page.search!(".athing").map{|item| HackerNewsItem.new(item) }
  end

end

class HackerNewsItem < Grubby::Scraper

  scrapes(:title) { @row1.at!(".storylink").text }
  scrapes(:submitter) { @row2.at!(".hnuser").text }
  scrapes(:story_uri) { URI.join(@base_uri, @row1.at!(".storylink")["href"]) }
  scrapes(:comments_uri) { URI.join(@base_uri, @row2.at!(".age a")["href"]) }

  def initialize(source)
    @row1 = source
    @row2 = source.next_sibling
    @base_uri = source.document.url
    super
  end

end

grubby = Grubby.new

# The following line will raise an exception if anything goes wrong
# during the scraping process.  For example, if the structure of the
# HTML does not match expectations, either due to a bad assumption or
# due to a site-wide change, the script will terminate immediately with
# a relevant error message.  This prevents bad values from propogating
# and causing hard-to-trace errors.
hn = HackerNews.new(grubby.get("https://news.ycombinator.com/news"))

puts hn.items.take(10).map(&:title) # your scraping logic goes here
```

[Hacker News]: https://news.ycombinator.com/news


## Core API

- [Grubby](http://www.rubydoc.info/gems/grubby/Grubby)
  - [#get_mirrored](http://www.rubydoc.info/gems/grubby/Grubby:get_mirrored)
  - [#singleton](http://www.rubydoc.info/gems/grubby/Grubby:singleton)
  - [#time_between_requests](http://www.rubydoc.info/gems/grubby/Grubby:time_between_requests)
- [Scraper](http://www.rubydoc.info/gems/grubby/Grubby/Scraper)
  - [.fields](http://www.rubydoc.info/gems/grubby/Grubby/Scraper.fields)
  - [.scrapes](http://www.rubydoc.info/gems/grubby/Grubby/Scraper.scrapes)
  - [#[]](http://www.rubydoc.info/gems/grubby/Grubby/Scraper:[])
  - [#source](http://www.rubydoc.info/gems/grubby/Grubby/Scraper:source)
  - [#to_h](http://www.rubydoc.info/gems/grubby/Grubby/Scraper:to_h)
- [PageScraper](http://www.rubydoc.info/gems/grubby/Grubby/PageScraper)
  - [#page](http://www.rubydoc.info/gems/grubby/Grubby/PageScraper:page)
- [JsonScraper](http://www.rubydoc.info/gems/grubby/Grubby/JsonScraper)
  - [#json](http://www.rubydoc.info/gems/grubby/Grubby/JsonScraper:json)
- Nokogiri::XML::Searchable
  - [#at!](http://www.rubydoc.info/gems/grubby/Nokogiri/XML/Searchable:at%21)
  - [#search!](http://www.rubydoc.info/gems/grubby/Nokogiri/XML/Searchable:search%21)
- Mechanize::Page
  - [#at!](http://www.rubydoc.info/gems/grubby/Mechanize/Page:at%21)
  - [#search!](http://www.rubydoc.info/gems/grubby/Mechanize/Page:search%21)
- Mechanize::Page::Link
  - [#to_absolute_uri](http://www.rubydoc.info/gems/grubby/Mechanize/Page/Link#to_absolute_uri)


## Supplemental API

*grubby* uses several gems which extend core Ruby objects with
convenience methods.  When you import *grubby* you automatically make
these methods available.  See each gem below for its specific API
documentation:

- [Active Support](https://rubygems.org/gems/activesupport)
  ([docs](http://www.rubydoc.info/gems/activesupport/))
- [casual_support](https://rubygems.org/gems/casual_support)
  ([docs](http://www.rubydoc.info/gems/casual_support/))
- [gorge](https://rubygems.org/gems/gorge)
  ([docs](http://www.rubydoc.info/gems/gorge/))
- [mini_sanity](https://rubygems.org/gems/mini_sanity)
  ([docs](http://www.rubydoc.info/gems/mini_sanity/))
- [pleasant_path](https://rubygems.org/gems/pleasant_path)
  ([docs](http://www.rubydoc.info/gems/pleasant_path/))


## Installation

Install from [Ruby Gems](https://rubygems.org/gems/grubby):

```bash
$ gem install grubby
```

Then require in your Ruby script:

```ruby
require "grubby"
```


## Contributing

Run `rake test` to run the tests.  You can also run `rake irb` for an
interactive prompt that pre-loads the project code.


## License

[MIT License](https://opensource.org/licenses/MIT)

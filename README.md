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
  - [#ok?](http://www.rubydoc.info/gems/grubby/Grubby:ok%3F)
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
- Mechanize::Page
  - [#at!](http://www.rubydoc.info/gems/grubby/Mechanize/Page:at%21)
  - [#search!](http://www.rubydoc.info/gems/grubby/Mechanize/Page:search%21)
- Mechanize::Page::Link
  - [#to_absolute_uri](http://www.rubydoc.info/gems/grubby/Mechanize/Page/Link#to_absolute_uri)


## Supplemental API

*grubby* includes several gems which extend Ruby objects with
convenience methods.  When you load *grubby* you automatically make
these methods available.  The included gems are listed below, along with
**a few** of the methods each provides.  See each gem's documentation
for a complete API listing.

- [Active Support](https://rubygems.org/gems/activesupport)
  ([docs](http://www.rubydoc.info/gems/activesupport/))
  - [Enumerable#index_by](https://www.rubydoc.info/gems/activesupport/Enumerable:index_by)
  - [File.atomic_write](https://www.rubydoc.info/gems/activesupport/File:atomic_write)
  - [NilClass#try](https://www.rubydoc.info/gems/activesupport/NilClass:try)
  - [Object#presence](https://www.rubydoc.info/gems/activesupport/Object:presence)
  - [String#blank?](https://www.rubydoc.info/gems/activesupport/String:blank%3F)
  - [String#squish](https://www.rubydoc.info/gems/activesupport/String:squish)
- [casual_support](https://rubygems.org/gems/casual_support)
  ([docs](http://www.rubydoc.info/gems/casual_support/))
  - [Enumerable#index_to](http://www.rubydoc.info/gems/casual_support/Enumerable:index_to)
  - [String#after](http://www.rubydoc.info/gems/casual_support/String:after)
  - [String#after_last](http://www.rubydoc.info/gems/casual_support/String:after_last)
  - [String#before](http://www.rubydoc.info/gems/casual_support/String:before)
  - [String#before_last](http://www.rubydoc.info/gems/casual_support/String:before_last)
  - [String#between](http://www.rubydoc.info/gems/casual_support/String:between)
  - [Time#to_hms](http://www.rubydoc.info/gems/casual_support/Time:to_hms)
  - [Time#to_ymd](http://www.rubydoc.info/gems/casual_support/Time:to_ymd)
- [gorge](https://rubygems.org/gems/gorge)
  ([docs](http://www.rubydoc.info/gems/gorge/))
  - [Pathname#file_crc32](http://www.rubydoc.info/gems/gorge/Pathname:file_crc32)
  - [Pathname#file_md5](http://www.rubydoc.info/gems/gorge/Pathname:file_md5)
  - [Pathname#file_sha1](http://www.rubydoc.info/gems/gorge/Pathname:file_sha1)
  - [String#crc32](http://www.rubydoc.info/gems/gorge/String:crc32)
  - [String#md5](http://www.rubydoc.info/gems/gorge/String:md5)
  - [String#sha1](http://www.rubydoc.info/gems/gorge/String:sha1)
- [mini_sanity](https://rubygems.org/gems/mini_sanity)
  ([docs](http://www.rubydoc.info/gems/mini_sanity/))
  - [Array#assert_length!](http://www.rubydoc.info/gems/mini_sanity/Array:assert_length%21)
  - [Enumerable#refute_empty!](http://www.rubydoc.info/gems/mini_sanity/Enumerable:refute_empty%21)
  - [Object#assert_equal!](http://www.rubydoc.info/gems/mini_sanity/Object:assert_equal%21)
  - [Object#assert_in!](http://www.rubydoc.info/gems/mini_sanity/Object:assert_in%21)
  - [Object#refute_nil!](http://www.rubydoc.info/gems/mini_sanity/Object:refute_nil%21)
  - [Pathname#assert_exist!](http://www.rubydoc.info/gems/mini_sanity/Pathname:assert_exist%21)
  - [String#assert_match!](http://www.rubydoc.info/gems/mini_sanity/String:assert_match%21)
- [pleasant_path](https://rubygems.org/gems/pleasant_path)
  ([docs](http://www.rubydoc.info/gems/pleasant_path/))
  - [Pathname#dirs](http://www.rubydoc.info/gems/pleasant_path/Pathname:dirs)
  - [Pathname#dirs_r](http://www.rubydoc.info/gems/pleasant_path/Pathname:dirs_r)
  - [Pathname#files](http://www.rubydoc.info/gems/pleasant_path/Pathname:files)
  - [Pathname#files_r](http://www.rubydoc.info/gems/pleasant_path/Pathname:files_r)
  - [Pathname#make_dirname](http://www.rubydoc.info/gems/pleasant_path/Pathname:make_dirname)
  - [Pathname#rename_basename](http://www.rubydoc.info/gems/pleasant_path/Pathname:rename_basename)
  - [Pathname#rename_extname](http://www.rubydoc.info/gems/pleasant_path/Pathname:rename_extname)
  - [Pathname#touch_file](http://www.rubydoc.info/gems/pleasant_path/Pathname:touch_file)
- [ryoba](https://rubygems.org/gems/ryoba)
  ([docs](http://www.rubydoc.info/gems/ryoba/))
  - [Nokogiri::XML::Node#matches!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:matches%21)
  - [Nokogiri::XML::Node#text!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:text%21)
  - [Nokogiri::XML::Node#uri](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:uri)
  - [Nokogiri::XML::Searchable#ancestor!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:ancestor%21)
  - [Nokogiri::XML::Searchable#ancestors!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:ancestors%21)
  - [Nokogiri::XML::Searchable#at!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:at%21)
  - [Nokogiri::XML::Searchable#search!](http://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:search%21)

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

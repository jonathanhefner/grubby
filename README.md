# grubby [![Build Status](https://travis-ci.org/jonathanhefner/grubby.svg?branch=master)](https://travis-ci.org/jonathanhefner/grubby)

[Fail-fast] web scraping.  *grubby* adds a layer of utility and
error-checking atop the marvelous [Mechanize gem].  See API summary
below, or browse the [full documentation].

[Fail-fast]: https://en.wikipedia.org/wiki/Fail-fast
[Mechanize gem]: https://rubygems.org/gems/mechanize
[full documentation]: https://www.rubydoc.info/gems/grubby/


## Examples

The following example scrapes stories from the [Hacker News] front page:

```ruby
require "grubby"

class HackerNews < Grubby::PageScraper
  scrapes(:items) do
    page.search!(".athing").map{|el| Item.new(el) }
  end

  class Item < Grubby::Scraper
    scrapes(:story_link){ source.at!("a.storylink") }
    scrapes(:story_uri){ story_link.uri }
    scrapes(:title){ story_link.text }
  end
end

# The following line will raise an exception if anything goes wrong
# during the scraping process.  For example, if the structure of the
# HTML does not match expectations, either due to incorrect assumptions
# or a site change, the script will terminate immediately with a helpful
# error message.  This prevents bad data from propagating and causing
# hard-to-trace errors.
hn = HackerNews.scrape("https://news.ycombinator.com/news")

# Your processing logic goes here:
hn.items.take(10).each do |item|
  puts "* #{item.title}"
  puts "  #{item.story_uri}"
  puts
end
```

[Hacker News]: https://news.ycombinator.com/news


## Core API

- [Grubby](https://www.rubydoc.info/gems/grubby/Grubby)
  - [#get_mirrored](https://www.rubydoc.info/gems/grubby/Grubby:get_mirrored)
  - [#ok?](https://www.rubydoc.info/gems/grubby/Grubby:ok%3F)
  - [#singleton](https://www.rubydoc.info/gems/grubby/Grubby:singleton)
  - [#time_between_requests](https://www.rubydoc.info/gems/grubby/Grubby:time_between_requests)
- [Scraper](https://www.rubydoc.info/gems/grubby/Grubby/Scraper)
  - [.each](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.each)
  - [.fields](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.fields)
  - [.scrape](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.scrape)
  - [.scrapes](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.scrapes)
  - [#[]](https://www.rubydoc.info/gems/grubby/Grubby/Scraper:[])
  - [#source](https://www.rubydoc.info/gems/grubby/Grubby/Scraper:source)
  - [#to_h](https://www.rubydoc.info/gems/grubby/Grubby/Scraper:to_h)
- [PageScraper](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper)
  - [.scrape_file](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper.scrape_file)
  - [#page](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper:page)
- [JsonScraper](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper)
  - [.scrape_file](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper.scrape_file)
  - [#json](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper:json)
- Mechanize::Download
  - [#save_to](https://www.rubydoc.info/gems/grubby/Mechanize/Parser:save_to)
  - [#save_to!](https://www.rubydoc.info/gems/grubby/Mechanize/Parser:save_to%21)
- Mechanize::File
  - [#save_to](https://www.rubydoc.info/gems/grubby/Mechanize/Parser:save_to)
  - [#save_to!](https://www.rubydoc.info/gems/grubby/Mechanize/Parser:save_to%21)
- Mechanize::Page
  - [#at!](https://www.rubydoc.info/gems/grubby/Mechanize/Page:at%21)
  - [#search!](https://www.rubydoc.info/gems/grubby/Mechanize/Page:search%21)
- Mechanize::Page::Link
  - [#to_absolute_uri](https://www.rubydoc.info/gems/grubby/Mechanize/Page/Link#to_absolute_uri)
- URI
  - [#basename](https://www.rubydoc.info/gems/grubby/URI:basename)
  - [#query_param](https://www.rubydoc.info/gems/grubby/URI:query_param)


## Supplemental API

*grubby* includes several gems which extend Ruby objects with
convenience methods.  When you load *grubby* you automatically make
these methods available.  The included gems are listed below, along with
**a few** of the methods each provides.  See each gem's documentation
for a complete API listing.

- [Active Support](https://rubygems.org/gems/activesupport)
  ([docs](https://www.rubydoc.info/gems/activesupport/))
  - [Enumerable#index_by](https://www.rubydoc.info/gems/activesupport/Enumerable:index_by)
  - [File.atomic_write](https://www.rubydoc.info/gems/activesupport/File:atomic_write)
  - [NilClass#try](https://www.rubydoc.info/gems/activesupport/NilClass:try)
  - [Object#presence](https://www.rubydoc.info/gems/activesupport/Object:presence)
  - [String#blank?](https://www.rubydoc.info/gems/activesupport/String:blank%3F)
  - [String#squish](https://www.rubydoc.info/gems/activesupport/String:squish)
- [casual_support](https://rubygems.org/gems/casual_support)
  ([docs](https://www.rubydoc.info/gems/casual_support/))
  - [Enumerable#index_to](https://www.rubydoc.info/gems/casual_support/Enumerable:index_to)
  - [String#after](https://www.rubydoc.info/gems/casual_support/String:after)
  - [String#after_last](https://www.rubydoc.info/gems/casual_support/String:after_last)
  - [String#before](https://www.rubydoc.info/gems/casual_support/String:before)
  - [String#before_last](https://www.rubydoc.info/gems/casual_support/String:before_last)
  - [String#between](https://www.rubydoc.info/gems/casual_support/String:between)
  - [Time#to_hms](https://www.rubydoc.info/gems/casual_support/Time:to_hms)
  - [Time#to_ymd](https://www.rubydoc.info/gems/casual_support/Time:to_ymd)
- [gorge](https://rubygems.org/gems/gorge)
  ([docs](https://www.rubydoc.info/gems/gorge/))
  - [Pathname#file_crc32](https://www.rubydoc.info/gems/gorge/Pathname:file_crc32)
  - [Pathname#file_md5](https://www.rubydoc.info/gems/gorge/Pathname:file_md5)
  - [Pathname#file_sha1](https://www.rubydoc.info/gems/gorge/Pathname:file_sha1)
  - [String#crc32](https://www.rubydoc.info/gems/gorge/String:crc32)
  - [String#md5](https://www.rubydoc.info/gems/gorge/String:md5)
  - [String#sha1](https://www.rubydoc.info/gems/gorge/String:sha1)
- [mini_sanity](https://rubygems.org/gems/mini_sanity)
  ([docs](https://www.rubydoc.info/gems/mini_sanity/))
  - [Array#assert_length!](https://www.rubydoc.info/gems/mini_sanity/Array:assert_length%21)
  - [Enumerable#refute_empty!](https://www.rubydoc.info/gems/mini_sanity/Enumerable:refute_empty%21)
  - [Object#assert_equal!](https://www.rubydoc.info/gems/mini_sanity/Object:assert_equal%21)
  - [Object#assert_in!](https://www.rubydoc.info/gems/mini_sanity/Object:assert_in%21)
  - [Object#refute_nil!](https://www.rubydoc.info/gems/mini_sanity/Object:refute_nil%21)
  - [Pathname#assert_exist!](https://www.rubydoc.info/gems/mini_sanity/Pathname:assert_exist%21)
  - [String#assert_match!](https://www.rubydoc.info/gems/mini_sanity/String:assert_match%21)
- [pleasant_path](https://rubygems.org/gems/pleasant_path)
  ([docs](https://www.rubydoc.info/gems/pleasant_path/))
  - [Pathname#available_name](https://www.rubydoc.info/gems/pleasant_path/Pathname:available_name)
  - [Pathname#dirs](https://www.rubydoc.info/gems/pleasant_path/Pathname:dirs)
  - [Pathname#files](https://www.rubydoc.info/gems/pleasant_path/Pathname:files)
  - [Pathname#make_dirname](https://www.rubydoc.info/gems/pleasant_path/Pathname:make_dirname)
  - [Pathname#make_file](https://www.rubydoc.info/gems/pleasant_path/Pathname:make_file)
  - [Pathname#move_as](https://www.rubydoc.info/gems/pleasant_path/Pathname:move_as)
  - [Pathname#rename_basename](https://www.rubydoc.info/gems/pleasant_path/Pathname:rename_basename)
  - [Pathname#rename_extname](https://www.rubydoc.info/gems/pleasant_path/Pathname:rename_extname)
- [ryoba](https://rubygems.org/gems/ryoba)
  ([docs](https://www.rubydoc.info/gems/ryoba/))
  - [Nokogiri::XML::Node#matches!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:matches%21)
  - [Nokogiri::XML::Node#text!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:text%21)
  - [Nokogiri::XML::Node#uri](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Node:uri)
  - [Nokogiri::XML::Searchable#ancestor!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:ancestor%21)
  - [Nokogiri::XML::Searchable#ancestors!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:ancestors%21)
  - [Nokogiri::XML::Searchable#at!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:at%21)
  - [Nokogiri::XML::Searchable#search!](https://www.rubydoc.info/gems/ryoba/Nokogiri/XML/Searchable:search%21)


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

Run `rake test` to run the tests.


## License

[MIT License](https://opensource.org/licenses/MIT)

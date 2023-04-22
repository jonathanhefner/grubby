# grubby

[Fail-fast] web scraping.  *grubby* adds a layer of utility and
error-checking atop the marvelous [Mechanize gem].  See API listing
below, or browse the [full documentation].

[Fail-fast]: https://en.wikipedia.org/wiki/Fail-fast
[Mechanize gem]: https://rubygems.org/gems/mechanize
[full documentation]: https://www.rubydoc.info/gems/grubby/


## Examples

The following code scrapes stories from the [Hacker News](
https://news.ycombinator.com/news) front page:

```ruby
require "grubby"

class HackerNews < Grubby::PageScraper
  scrapes(:items) do
    page.search!(".athing").map{|element| Item.new(element) }
  end

  class Item < Grubby::Scraper
    scrapes(:story_link){ source.at!("a.storylink") }

    scrapes(:story_url){ expand_url(story_link["href"]) }

    scrapes(:title){ story_link.text }

    scrapes(:comments_link, optional: true) do
      source.next_sibling.search!(".subtext a").find do |link|
        link.text.match?(/comment|discuss/)
      end
    end

    scrapes(:comments_url, if: :comments_link) do
      expand_url(comments_link["href"])
    end

    scrapes(:comment_count, if: :comments_link) do
      comments_link.text.to_i
    end

    def expand_url(url)
      url.include?("://") ? url : source.document.uri.merge(url).to_s
    end
  end
end

# The following line will raise an exception if anything goes wrong
# during the scraping process.  For example, if the structure of the
# HTML does not match expectations due to a site change, the script will
# terminate immediately with a helpful error message.  This prevents bad
# data from propagating and causing hard-to-trace errors.
hn = HackerNews.scrape("https://news.ycombinator.com/news")

# Your processing logic goes here:
hn.items.take(10).each do |item|
  puts "* #{item.title}"
  puts "  #{item.story_url}"
  puts "  #{item.comment_count} comments: #{item.comments_url}" if item.comments_url
  puts
end
```

Hacker News also offers a [JSON API](https://github.com/HackerNews/API),
which may be more robust for scraping purposes.  *grubby* can scrape
JSON just as well:

```ruby
require "grubby"

class HackerNews < Grubby::JsonScraper
  scrapes(:items) do
    # API returns array of top 500 item IDs, so limit as necessary
    json.take(10).map do |item_id|
      Item.scrape("https://hacker-news.firebaseio.com/v0/item/#{item_id}.json")
    end
  end

  class Item < Grubby::JsonScraper
    scrapes(:story_url){ json["url"] || hn_url }

    scrapes(:title){ json["title"] }

    scrapes(:comments_url, optional: true) do
      hn_url if json["descendants"]
    end

    scrapes(:comment_count, optional: true) do
      json["descendants"]&.to_i
    end

    def hn_url
      "https://news.ycombinator.com/item?id=#{json["id"]}"
    end
  end
end

hn = HackerNews.scrape("https://hacker-news.firebaseio.com/v0/topstories.json")

# Your processing logic goes here:
hn.items.each do |item|
  puts "* #{item.title}"
  puts "  #{item.story_url}"
  puts "  #{item.comment_count} comments: #{item.comments_url}" if item.comments_url
  puts
end
```


## Core API

- [Grubby](https://www.rubydoc.info/gems/grubby/Grubby)
  - [#fulfill](https://www.rubydoc.info/gems/grubby/Grubby:fulfill)
  - [#get_mirrored](https://www.rubydoc.info/gems/grubby/Grubby:get_mirrored)
  - [#ok?](https://www.rubydoc.info/gems/grubby/Grubby:ok%3F)
  - [#time_between_requests](https://www.rubydoc.info/gems/grubby/Grubby:time_between_requests)
- [Scraper](https://www.rubydoc.info/gems/grubby/Grubby/Scraper)
  - [.each](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.each)
  - [.scrape](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.scrape)
  - [.scrapes](https://www.rubydoc.info/gems/grubby/Grubby/Scraper.scrapes)
  - [#[]](https://www.rubydoc.info/gems/grubby/Grubby/Scraper:[])
  - [#to_h](https://www.rubydoc.info/gems/grubby/Grubby/Scraper:to_h)
- [PageScraper](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper)
  - [.scrape_file](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper.scrape_file)
  - [#page](https://www.rubydoc.info/gems/grubby/Grubby/PageScraper:page)
- [JsonScraper](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper)
  - [.scrape_file](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper.scrape_file)
  - [#json](https://www.rubydoc.info/gems/grubby/Grubby/JsonScraper:json)
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


## Auxiliary API

*grubby* loads a few gems that extend Ruby objects with utility methods.
Some of those methods are listed below.  See each gem's documentation
for a complete API listing.

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
- [mini_sanity](https://rubygems.org/gems/mini_sanity)
  ([docs](https://www.rubydoc.info/gems/mini_sanity/))
  - [Enumerator#result!](https://www.rubydoc.info/gems/mini_sanity/Enumerator:result%21)
  - [Enumerator#results!](https://www.rubydoc.info/gems/mini_sanity/Enumerator:results%21)
  - [Object#assert!](https://www.rubydoc.info/gems/mini_sanity/Object:assert%21)
  - [Object#refute!](https://www.rubydoc.info/gems/mini_sanity/Object:refute%21)
  - [String#match!](https://www.rubydoc.info/gems/mini_sanity/String:match%21)
- [pleasant_path](https://rubygems.org/gems/pleasant_path)
  ([docs](https://www.rubydoc.info/gems/pleasant_path/))
  - [Pathname#available_name](https://www.rubydoc.info/gems/pleasant_path/Pathname:available_name)
  - [Pathname#existence](https://www.rubydoc.info/gems/pleasant_path/Pathname:existence)
  - [Pathname#make_dirname](https://www.rubydoc.info/gems/pleasant_path/Pathname:make_dirname)
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


## Recommended Gems

The following gems will extend Ruby objects with utility methods that
can be useful when web scraping.  Example methods are listed; see each
gem's documentation for a complete API listing.

- [Active Support](https://rubygems.org/gems/activesupport)
  ([docs](https://www.rubydoc.info/gems/activesupport/))
  - [Enumerable#index_by](https://www.rubydoc.info/gems/activesupport/Enumerable:index_by)
  - [File.atomic_write](https://www.rubydoc.info/gems/activesupport/File:atomic_write)
  - [Object#presence](https://www.rubydoc.info/gems/activesupport/Object:presence)
  - [String#blank?](https://www.rubydoc.info/gems/activesupport/String:blank%3F)
  - [String#squish](https://www.rubydoc.info/gems/activesupport/String:squish)


## Installation

Install the [`grubby` gem](https://rubygems.org/gems/grubby).


## Contributing

Run `rake test` to run the tests.


## License

[MIT License](LICENSE.txt)

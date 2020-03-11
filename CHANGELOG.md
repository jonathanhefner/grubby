## 2.0.0

* [BREAKING] Drop support for Active Support < 6.0
* [BREAKING] Require casual_support ~> 4.0
* [BREAKING] Require mini_sanity ~> 2.0
* [BREAKING] Require pleasant_path ~> 2.0
* [BREAKING] Remove `JsonParser.json_parse_options`
  * Use `::JSON.load_default_options` instead
* [BREAKING] Rename `Grubby#singleton` to `Grubby#fulfill`
* [BREAKING] Change `Grubby#fulfill` to return block's result


## 1.2.1

* Add `JsonParser#mech` attribute for parity with `Mechanize::Page#mech`
* Ensure time spent fetching a response does not count toward the time
  to sleep between requests
* Prevent sleep between requests when following a redirect
* Prevent duplicates in `Scraper.fields`
* Fix `URI#query_param` when query is nil
* Fix `PageScraper.scrape_file` and `JsonScraper.scrape_file` when path
  contains characters that need to be URI-encoded


## 1.2.0

* Add `Grubby#journal=`
* Add `$grubby` global default `Grubby` instance
* Add `Scraper.scrape`
* Add `Scraper.each`
* Support `:if` and `:unless` options for `Scraper.scrapes`
* Fix fail-fast behavior of inherited scraper fields
* Fix `JsonParser` on empty response body
* Loosen Active Support version constraint


## 1.1.0

* Add `Grubby#ok?`
* Add `PageScraper.scrape_file` and `JsonScraper.scrape_file`
* Add `Mechanize::Parser#save_to` and `Mechanize::Parser#save_to!`,
  which are inherited by `Mechanize::Download` and `Mechanize::File`
* Add `URI#basename`
* Add `URI#query_param`
* Add utility methods from [ryoba](https://rubygems.org/gems/ryoba)
* Add `Scraper::Error#scraper` and `Scraper#errors` for interactive
  debugging with e.g. `byebug`
* Improve log messages and error formatting
* Fix compatibility with net-http-persistent gem v3.0


## 1.0.0

* Initial release

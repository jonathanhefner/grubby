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

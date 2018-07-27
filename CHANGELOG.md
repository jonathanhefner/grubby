## 1.1.0
* Added `Grubby#ok?`.
* Added `Grubby::PageScraper.scrape_file` and `Grubby::JsonScraper.scrape_file`.
* Added `Mechanize::Parser#save_to` and `Mechanize::Parser#save_to!`,
  which are inherited by `Mechanize::Download` and `Mechanize::File`.
* Added `URI#basename`.
* Added `URI#query_param`.
* Added utility methods from [ryoba](https://rubygems.org/gems/ryoba).
* Added `Grubby::Scraper::Error#scraper` and `Grubby::Scraper#errors`
  for interactive debugging with e.g. byebug.
* Improved log messages and error formatting.
* Fixed compatibility with net-http-persistent gem v3.0.


## 1.0.0

* Initial release

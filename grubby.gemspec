# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "grubby/version"

Gem::Specification.new do |spec|
  spec.name          = "grubby"
  spec.version       = GRUBBY_VERSION
  spec.authors       = ["Jonathan Hefner"]
  spec.email         = ["jonathan.hefner@gmail.com"]

  spec.summary       = %q{Fail-fast web scraping}
  spec.homepage      = "https://github.com/jonathanhefner/grubby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 5.0"
  spec.add_runtime_dependency "casual_support", "~> 3.0"
  spec.add_runtime_dependency "gorge", "~> 1.0"
  spec.add_runtime_dependency "mechanize", "~> 2.7"
  spec.add_runtime_dependency "mini_sanity", "~> 1.0"
  spec.add_runtime_dependency "pleasant_path", "~> 1.1"
  spec.add_runtime_dependency "ryoba", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "yard", "~> 0.9"
end

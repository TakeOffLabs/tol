# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tol/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alex Tandrau"]
  gem.email         = ["alex@takeofflabs.com"]
  gem.description   = %q{A collection of tools used at Take Off Labs for Rails development}
  gem.summary       = %q{Heroku interactions, etc.}
  gem.homepage      = "http://www.takeofflabs.com"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "tol"
  gem.require_paths = ["lib"]
  gem.version       = Tol::VERSION

  # Development tools
  gem.add_development_dependency "pry"

  # Runtime gems
  gem.add_dependency "rainbow" # https://github.com/sickill/rainbow
  gem.add_dependency "highline"
end

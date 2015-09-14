# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-devpost/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ross Kaffenberger"]
  gem.email         = ["rosskaff@gmail.com"]
  gem.description   = %q{Official OmniAuth strategy for Devpost.}
  gem.summary       = %q{Official OmniAuth strategy for Devpost.}
  gem.homepage      = "https://github.com/challengepost/omniauth-devpost"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = "omniauth-devpost"
  gem.require_paths = ["lib"]
  gem.version       = Omniauth::Devpost::VERSION

  gem.add_dependency 'omniauth-oauth2', '~> 1.1'

  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rake'
end

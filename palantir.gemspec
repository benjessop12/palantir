# frozen_string_literal: true

lib = File.expand_path 'lib', __dir__

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'palantir/version'

Gem::Specification.new do |spec|
  spec.name = 'palantir'
  spec.version = Palantir::VERSION
  spec.authors = ['Ben Jessop']
  spec.date = '2020-12-11'
  spec.summary = 'Gamble your money with algo trading'
  spec.files = 'git ls-files'.split($RS)
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7.1'

  spec.add_dependency 'httpclient'
  spec.add_dependency 'parallel'
  spec.add_dependency 'pg'
  spec.add_dependency 'rake'

  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'webmock'
end

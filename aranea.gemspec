lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'aranea/version'

Gem::Specification.new do |s|
  s.name                      = 'aranea'
  s.version                   = Aranea::VERSION
  s.authors                   = ['Aaron Weiner', 'Matthew Szenher']
  s.email                     = s.authors.map{|name|name.sub(/(.).* (.*)/,'\1\2@mdsol.com')}
  s.homepage                  = 'https://github.com/mdsol/aranea'
  s.summary                   = 'Middleware for fault tolerance testing'
  s.description               = 'Rack and Faraday middleware to temporarily disable connections to external dependencies'
  s.license                   = 'MIT'

  s.required_rubygems_version = ">= 1.3.5"

  s.files                     = Dir.glob("{bin,lib}/**/*")
  s.require_path              = 'lib'

  s.add_dependency 'faraday'
  s.add_dependency 'rack'
  s.add_dependency 'activesupport'

  s.add_development_dependency 'rails'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'pry-byebug'
end

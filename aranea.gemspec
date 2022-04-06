# frozen_string_literal: true

require_relative "lib/aranea/version"

Gem::Specification.new do |s|
  s.name        = "aranea"
  s.version     = Aranea::VERSION
  s.authors     = ["Aaron Weiner", "Matthew Szenher"]
  s.email       = s.authors.map { |name| name.sub(/(.).* (.*)/, '\1\2@mdsol.com') }
  s.homepage    = "https://github.com/mdsol/aranea"
  s.summary     = "Middleware for fault tolerance testing"
  s.description = "Rack and Faraday middleware to temporarily disable connections to external dependencies"
  s.license     = "MIT"

  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = "#{s.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 4.2"
  s.add_dependency "faraday", ">= 0.9", "< 3.0"
  s.add_dependency "rack"

  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "rails"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rubocop", "= 1.26.1"
  s.add_development_dependency "rubocop-mdsol", "~> 0.1"
  s.add_development_dependency "rubocop-performance", "= 1.13.3"
end

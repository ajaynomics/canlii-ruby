# frozen_string_literal: true

require_relative "lib/canlii/version"

Gem::Specification.new do |spec|
  spec.name          = "canlii-ruby"
  spec.version       = CanLII::VERSION
  spec.authors       = ["Ajay Krishnan"]
  spec.email         = ["50063680+ajaynomics@users.noreply.github.com"]
  spec.summary       = "Ruby client for the CanLII API"
  spec.description   = "A lightweight Ruby client for accessing Canadian legal information via the CanLII API"
  spec.homepage      = "https://github.com/youraccount/canlii-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "http", "~> 5.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end

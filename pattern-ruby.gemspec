require_relative "lib/pattern_ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "pattern-ruby"
  spec.version       = PatternRuby::VERSION
  spec.authors       = ["Johannes Dwi Cahyo"]
  spec.summary       = "Deterministic pattern detection and intent matching engine for Ruby"
  spec.description   = "A rule-based pattern matching engine for chatbots and conversational AI. " \
                        "Provides a DSL for defining intents, extracting entities, and routing " \
                        "user input — deterministically, with zero latency and no API calls."
  spec.homepage      = "https://github.com/johannesdwicahyo/pattern-ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir[
    "lib/**/*.rb",
    "examples/**/*.rb",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "Rakefile",
    "pattern-ruby.gemspec"
  ]

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/blob/main/CHANGELOG.md",
  }

  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end

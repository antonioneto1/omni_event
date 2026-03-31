# frozen_string_literal: true

require_relative "lib/omni_event/version"

Gem::Specification.new do |spec|
  spec.name    = "omni_events"
  spec.version = OmniEvent::VERSION
  spec.authors = ["Antonio Neto"]
  spec.email   = ["antonioneto1.dev@gmail.com"]

  spec.summary     = "Rails Engine for unified Webhook ingestion, Polymorphic Logging, and Process Traceability."
  spec.description = "OmniEvent unifies external event ingestion with detailed internal auditing via a step-based pipeline and asynchronous monitoring."
  spec.homepage    = "https://github.com/antonioneto1/omni_event"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) || f.end_with?(".gem")
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 6.1"
  spec.add_dependency "httparty", "~> 0.21"

  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
end
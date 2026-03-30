# frozen_string_literal: true

require_relative "lib/omni_event/version"

Gem::Specification.new do |spec|
  spec.name    = "omni_event"
  spec.version = OmniEvent::VERSION
  spec.authors = ["Antonio Neto"]
  spec.email   = ["antoniocneto.dev@gmail.com"]

  spec.summary     = "Rails Engine for unified Webhook ingestion, Polymorphic Logging, and Process Traceability."
  spec.description = "OmniEvent unifies external event ingestion with detailed internal auditing via a step-based pipeline and asynchronous monitoring."
  spec.homepage    = "https://github.com/antoniocneto/omni_event"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ .git .circleci appveyor])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "httparty", "~> 0.21"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "factory_bot_rails"
end
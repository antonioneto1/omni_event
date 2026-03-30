# frozen_string_literal: true

require 'logger'

# ── Integration mode ──────────────────────────────────────────────────────────
# Set INTEGRATION=1 to load the full dummy Rails app and run model/job specs.
#
#   INTEGRATION=1 bundle exec rspec
#
if ENV['INTEGRATION']
  ENV['RAILS_ENV'] ||= 'test'
  require File.expand_path('dummy/config/environment', __dir__)
  require 'rspec/rails'
  require 'factory_bot_rails'

  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
    config.use_transactional_fixtures = true

    config.before(:suite) do
      ActiveRecord::Schema.verbose = false
      load File.expand_path('dummy/db/schema.rb', __dir__)
    end
  end

# ── Unit mode (default) ───────────────────────────────────────────────────────
# Minimal Rails stubs — no database, no full app. Fast.
else
  require 'active_support/core_ext/string/inflections'

  module Rails
    def self.logger
      @logger ||= Logger.new(nil)
    end

    class Engine
      def self.inherited(base); end
      def self.isolate_namespace(mod); end
    end
  end

  require 'omni_event'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order    = :random
  Kernel.srand config.seed

  config.before(:each) do
    OmniEvent.configuration = nil
  end
end

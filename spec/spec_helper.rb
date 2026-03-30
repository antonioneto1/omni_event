# frozen_string_literal: true

require 'logger'
require 'active_support/core_ext/string/inflections'

# Minimal Rails stubs so unit tests run without a full Rails application.
# Integration tests requiring ActiveRecord models need a spec/dummy app.
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
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    OmniEvent.configuration = nil
  end
end

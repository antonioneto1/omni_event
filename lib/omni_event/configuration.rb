# frozen_string_literal: true

module OmniEvent
  class Configuration
    attr_accessor :new_relic_enabled,
                  :new_relic_api_key,
                  :new_relic_account_id,
                  :retention_days,
                  :process_async,
                  :custom_log_types

    def initialize
      @new_relic_enabled    = false
      @new_relic_api_key    = nil
      @new_relic_account_id = nil
      @retention_days       = 30
      @process_async        = true
      @custom_log_types     = { system_info: 0, system_error: 1 }
    end
  end
end

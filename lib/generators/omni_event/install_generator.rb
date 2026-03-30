# frozen_string_literal: true

require 'rails/generators/migration'

module OmniEvent
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def copy_migrations
        rake "omni_event:install:migrations"
      end

      def create_initializer
        create_file "config/initializers/omni_event.rb", <<~RUBY
          OmniEvent.configure do |config|
            config.new_relic_enabled    = false
            config.new_relic_api_key    = ENV['NEW_RELIC_KEY']
            config.new_relic_account_id = ENV['NEW_RELIC_ACCOUNT_ID']
            config.retention_days       = 30
            config.process_async        = true

            # Define your custom action_types here
            config.custom_log_types = {
              system_info:  0,
              system_error: 1
            }
          end
        RUBY
      end

      def create_local_models
        create_file "app/models/log.rb", <<~RUBY
          class Log < OmniEvent::Log
            # Add custom validations or methods specific to your application here
          end
        RUBY

        create_file "app/models/webhook_event.rb", <<~RUBY
          class WebhookEvent < OmniEvent::WebhookEvent
          end
        RUBY
      end

      def display_post_install_message
        puts ""
        puts "================================================================"
        puts " OmniEvent installed successfully!"
        puts " 1. Run 'rails db:migrate' to create the database tables."
        puts " 2. Configure your initializer at config/initializers/omni_event.rb"
        puts " 3. Your logs are now accessible via the 'Log' class."
        puts "================================================================"
      end
    end
  end
end

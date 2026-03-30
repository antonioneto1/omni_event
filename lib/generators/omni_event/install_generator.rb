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
            # ── Monitoring ────────────────────────────────────────────────────────────
            config.new_relic_enabled    = false
            config.new_relic_api_key    = ENV['NEW_RELIC_KEY']
            config.new_relic_account_id = ENV['NEW_RELIC_ACCOUNT_ID']

            # ── Processing ────────────────────────────────────────────────────────────
            config.process_async  = true   # set false to process synchronously
            config.retention_days = 30

            # ── Custom log types ──────────────────────────────────────────────────────
            # Define your domain-specific action types here.
            config.custom_log_types = {
              system_info:  0,
              system_error: 1
            }

            # ── Processor registry ────────────────────────────────────────────────────
            # Map each OmniEvent::Notifier name to its processor class.
            #
            #   config.processors = {
            #     "Siscomex" => SiscomexProcessor,
            #     "DHL"      => DHLWebhookProcessor
            #   }
            config.processors = {}
          end
        RUBY
      end

      def create_local_models
        create_file "app/models/log.rb", <<~RUBY
          class Log < OmniEvent::Log
            # Add custom scopes, validations or methods here.
          end
        RUBY

        create_file "app/models/webhook_event.rb", <<~RUBY
          class WebhookEvent < OmniEvent::WebhookEvent
          end
        RUBY
      end

      def display_post_install_message
        puts ""
        puts "=" * 64
        puts " OmniEvent #{OmniEvent::VERSION} installed successfully!"
        puts ""
        puts " Next steps:"
        puts " 1. rails db:migrate"
        puts " 2. Configure config/initializers/omni_event.rb"
        puts " 3. Mount the engine in config/routes.rb:"
        puts "      mount OmniEvent::Engine => '/omni_events'"
        puts " 4. Create a Notifier:"
        puts "      OmniEvent::Notifier.create!(name: 'My Partner')"
        puts " 5. Register a processor in the initializer:"
        puts "      config.processors = { 'My Partner' => MyProcessor }"
        puts "=" * 64
      end
    end
  end
end

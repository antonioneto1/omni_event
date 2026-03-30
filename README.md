# 🚀 OmniEvent
> *"One Gem to rule them all, One Gem to find them, One Gem to bring all logs, and in the shadows, trace them."*

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![Gem Version](https://img.shields.io/badge/gem-v1.0.0-blue.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Rails Version](https://img.shields.io/badge/rails-6.1+-red.svg)](#)

**OmniEvent** is a robust, production-ready Ruby on Rails Engine designed to unify the system's event lifecycle. It bridges the gap between external Webhook ingestion and internal process auditing, transforming complex background logic into a single, traceable flow.

---

## 🌟 Key Features

* **Polymorphic Logging**: Attach logs to any model (`Master`, `Order`, `User`, etc.) using a unified, high-performance architecture.
* **Step Pipeline**: Organize complex business logic into traceable methods with automatic error capturing and business-context logging.
* **Secure Webhooks**: Built-in Token authentication and IP Whitelisting, configurable per Notifier (Client).
* **Async Monitoring**: Native, non-blocking integration with **New Relic Insights** via ActiveJob for high-performance telemetry.
* **Smart Cleanup**: Built-in Rake tasks for data retention, keeping your production database lean and healthy.
* **Zero-Boilerplate DX**: Clean syntax inspired by Rails callbacks with a Devise-like installation process.

---

## 🛠 Installation

1. Add this line to your application's `Gemfile`:

    ```ruby
    gem 'omni_event'
    ```

2. Execute the installer to generate migrations, configuration files, and local proxy models:

    ```bash
    bundle install
    rails generate omni_event:install
    rails db:migrate
    ```

3. Mount the engine in your `config/routes.rb`:

    ```ruby
    mount OmniEvent::Engine => "/omni_events"
    ```

---

## 💡 How to Use

### 1. Define a Processor (The Pipeline)

Forget messy `begin/rescue` blocks. Define your business logic as clear steps. OmniEvent automatically handles the logging and error context for each stage.

```ruby
# app/services/webhooks/siscomex_processor.rb
class SiscomexProcessor < OmniEvent::BaseProcessor
  steps :validate_payload,
        :send_to_government_api,
        :update_internal_status

  def validate_payload
    raise "Invalid Master ID" if event.payload[:master_id].blank?
  end

  def send_to_government_api
    # Your external API integration logic (e.g., Siscomex, SAP, etc.)
    ExternalApi.post(event.payload)
  end

  def update_internal_status
    event.loggable.update!(status: :processed)
  end
end
```

### 2. Native-like Logging

Once installed, use the `Log` class directly. It feels like a native part of your app but carries all of OmniEvent's tracking power.

```ruby
Log.create!(
  loggable: @master,
  action_type: :system_info,
  content: "Starting bulk manifest synchronization for CEVA Logistics"
)
```

---

## 🔧 Customization & Extensibility

### Custom Log Types

Define your own business-specific log levels in the initializer to categorize events beyond simple "info" or "error".

```ruby
# config/initializers/omni_event.rb
OmniEvent.configure do |config|
  config.custom_log_types = {
    system_info:       0,
    system_error:      1,
    cargo_tracking:    10,
    fiscal_validation: 20
  }
end
```

### Extending Local Models

Since the installer creates `app/models/log.rb` in your app, you can add custom scopes or methods:

```ruby
# app/models/log.rb
class Log < OmniEvent::Log
  scope :critical_logistics, -> { where(action_type: 20).where('created_at > ?', 1.day.ago) }
end
```

---

## ⚙️ Advanced Configuration

### 1. Webhook Security

OmniEvent secures your endpoints out of the box. Each Notifier (client) has its own security profile:

```ruby
notifier = OmniEvent::Notifier.create!(
  name:        "Logistics Partner",
  token:       SecureRandom.hex(24),
  check_ip:    true,
  allowed_ips: ["192.168.1.1"]
)
# Endpoint: POST /omni_events/receiver/#{notifier.token}
```

### 2. Database Maintenance (Auto-Cleanup)

Prevent database bloating by running the built-in cleanup task based on your `retention_days` setting:

```bash
rake omni_event:cleanup
```

### 3. Monitoring (New Relic)

OmniEvent dispatches events to New Relic Insights asynchronously.

```ruby
OmniEvent.configure do |config|
  config.new_relic_enabled = true
  config.new_relic_api_key = ENV['NR_KEY']
  config.process_async    = true
end
```

---

## 🐳 Docker Development

This gem is built with a container-first mindset.

```bash
docker compose up -d
docker compose exec app bash
bundle exec rspec
```

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Developed with ❤️ by Antonio

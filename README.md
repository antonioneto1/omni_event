# 🚀 OmniEvent

> *"One Gem to rule them all, One Gem to find them, One Gem to bring all logs, and in the shadows, trace them."*

[![Gem Version](https://img.shields.io/badge/gem-v0.1.1-blue.svg)](#)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Rails Version](https://img.shields.io/badge/rails-6.1+-red.svg)](#)

**OmniEvent** is a production-ready Rails Engine that unifies your system's entire event lifecycle — from secure external webhook ingestion to detailed internal process auditing — through a single, traceable pipeline.

---

## Table of Contents

- [Key Features](#-key-features)
- [Installation](#️-installation)
- [Configuration](#-configuration)
- [Receiving Webhooks](#-receiving-webhooks)
- [Processing Pipeline](#-processing-pipeline)
- [Polymorphic Logging](#-polymorphic-logging)
- [Security](#-security)
- [Database Maintenance](#️-database-maintenance)
- [Testing](#-testing)
- [Docker Development](#-docker-development)

---

## 🌟 Key Features

- **Secure Webhook Receiver** — token auth, IP whitelisting, HMAC signature verification, and replay attack protection out of the box.
- **Step Pipeline** — organize complex business logic into traceable steps with automatic error capturing and context logging.
- **Polymorphic Logging** — attach structured logs to any model (`Order`, `User`, `Payment`, etc.) with a unified API.
- **Processor Registry** — map each webhook source (Notifier) to its own processor class via configuration.
- **Async Monitoring** — non-blocking New Relic Insights integration via ActiveJob.
- **Smart Cleanup** — built-in Rake task for data retention based on configurable `retention_days`.
- **Zero-Boilerplate DX** — Devise-like installation, Rails callback-inspired syntax.

---

## 🛠️ Installation

**1. Add to your Gemfile:**

```ruby
gem 'omni_event'
```

**2. Run the installer:**

```bash
bundle install
rails generate omni_event:install
rails db:migrate
```

The generator creates:
- `config/initializers/omni_event.rb` — your configuration file
- `app/models/log.rb` — local proxy for `OmniEvent::Log`
- `app/models/webhook_event.rb` — local proxy for `OmniEvent::WebhookEvent`

**3. Mount the engine in `config/routes.rb`:**

```ruby
mount OmniEvent::Engine => "/omni_events"
# Exposes: POST /omni_events/receiver/:token
```

---

## ⚙️ Configuration

All options live in `config/initializers/omni_event.rb`:

```ruby
OmniEvent.configure do |config|
  # ── Monitoring ─────────────────────────────────────────────────────────────
  config.new_relic_enabled    = true
  config.new_relic_api_key    = ENV['NEW_RELIC_KEY']
  config.new_relic_account_id = ENV['NEW_RELIC_ACCOUNT_ID']

  # ── Processing ─────────────────────────────────────────────────────────────
  config.process_async  = true  # false = synchronous (useful for testing)
  config.retention_days = 30    # used by rake omni_event:cleanup

  # ── Custom log types ────────────────────────────────────────────────────────
  # Define domain-specific action types for your business context.
  config.custom_log_types = {
    system_info:       0,
    system_error:      1,
    payment_received:  10,
    user_update:       20,
    fiscal_validation: 30
  }

  # ── Processor registry ──────────────────────────────────────────────────────
  # Maps each Notifier name to the processor class that handles its events.
  config.processors = {
    "PaymentGateway" => Webhooks::PaymentGatewayProcessor,
    "BillingService" => Webhooks::BillingServiceProcessor,
    "CrmSystem"      => Webhooks::CrmSystemProcessor
  }
end
```

---

## 📡 Receiving Webhooks

### 1. Create a Notifier

A **Notifier** represents one external webhook source (e.g. a payment gateway, a payment processor). Each has its own security configuration.

```ruby
# Minimal — token auth only
notifier = OmniEvent::Notifier.create!(name: "Stripe")
# => token is auto-generated: SecureRandom.hex(24)

# Full security configuration
notifier = OmniEvent::Notifier.create!(
  name:                "Payment Gateway",
  secret_key:          ENV['WEBHOOK_SECRET'], # enables HMAC verification
  timestamp_tolerance: 300,                        # 5-minute replay window (seconds)
  check_ip:            true,
  allowed_ips:         ["185.60.216.35", "185.60.218.35"]
)

# The webhook endpoint for this notifier:
# POST /omni_events/receiver/#{notifier.token}
puts notifier.token  # => "a3f9c2b1e4d7..."
```

### 2. Register the processor

In `config/initializers/omni_event.rb`, map the notifier name to a processor class:

```ruby
config.processors = {
  "Payment Gateway" => Webhooks::PaymentGatewayProcessor
}
```

### 3. Send a webhook

The partner sends a `POST` request to your endpoint:

```bash
curl -X POST https://yourapp.com/omni_events/receiver/a3f9c2b1e4d7... \
  -H "Content-Type: application/json" \
  -H "X-OmniEvent-Timestamp: $(date +%s)" \
  -H "X-OmniEvent-Signature: sha256=$(echo -n '{"event":"payment.confirmed"}' | openssl dgst -sha256 -hmac 'your_secret')" \
  -d '{"event":"payment.confirmed","charge_id":"ch_abc123","status":"paid"}'
```

The receiver will:
1. Validate payload size (max 1MB)
2. Authenticate via token
3. Check IP whitelist (if enabled)
4. Verify HMAC signature + timestamp (if `secret_key` is set)
5. Persist the `WebhookEvent`
6. Dispatch to the registered processor (async or sync)

---

## 🔄 Processing Pipeline

Define your business logic as a sequence of named steps. OmniEvent automatically logs any step failure with full context (step name, error class, backtrace).

```ruby
# app/services/webhooks/payment_gateway_processor.rb
class Webhooks::PaymentGatewayProcessor < OmniEvent::BaseProcessor
  steps :validate_payload,
        :update_payment_status,
        :notify_customer,
        :record_audit_log

  def validate_payload
    raise "Missing charge ID" if event.payload[:charge_id].blank?
    raise "Unknown status '#{event.payload[:status]}'" unless valid_status?
  end

  def update_payment_status
    payment.update!(status: event.payload[:status])
  end

  def notify_customer
    CustomerMailer.payment_update(payment).deliver_later
  end

  def record_audit_log
    Log.create!(
      loggable:    payment,
      action_type: :payment_processed,
      content:     "Payment status updated to '#{event.payload[:status]}'",
      metadata:    { gateway: "Stripe", source: "webhook", timestamp: Time.current.iso8601 }
    )
  end

  private

  def payment
    @payment ||= Payment.find_by!(charge_id: event.payload[:charge_id])
  end

  def valid_status?
    %w[paid pending failed refunded disputed].include?(event.payload[:status])
  end
end
```

When a step raises an error, OmniEvent automatically creates a `system_error` log with the context and re-raises so the job can retry:

```ruby
# Auto-created by OmniEvent on step failure:
OmniEvent::Log.create!(
  loggable:    event,
  action_type: :system_error,
  content:     "FAILURE in step [Validate payload]: Missing charge ID",
  metadata:    {
    error_class: "RuntimeError",
    method:      :validate_payload,
    backtrace:   [...]
  }
)
```

---

## 📋 Polymorphic Logging

Use `Log` (the local proxy generated by the installer) to attach structured log entries to any model.

```ruby
# Attach to any ActiveRecord model
Log.create!(
  loggable:    @order,
  action_type: :payment_received,
  content:     "Payment of R$ 1.250,00 confirmed via PIX",
  metadata:    { gateway: "Stripe", charge_id: "ch_abc123", amount_cents: 125_000 }
)

# Query logs for a specific record
@order.logs.where(action_type: :system_error).order(created_at: :desc)

# Custom scopes on your local Log model (app/models/log.rb)
class Log < OmniEvent::Log
  scope :recent_errors, -> { where(action_type: :system_error).where('created_at > ?', 24.hours.ago) }
  scope :for_gateway,   ->(gw) { where("metadata->>'gateway' = ?", gw) }
end
```

### Custom log types

Define your domain vocabulary in the initializer:

```ruby
config.custom_log_types = {
  system_info:       0,
  system_error:      1,
  payment_received:  10,
  payment_failed:    11,
  payment_processed: 20,
  fiscal_validation: 30
}
```

---

## 🔒 Security

OmniEvent provides **4 independent security layers**, all configurable per Notifier. Each layer is opt-in and backward compatible.

### Layer 1 — Token Authentication

Every webhook endpoint is identified by a unique, cryptographically random token (48-char hex). Requests without a valid token receive `401 Unauthorized`.

```ruby
notifier = OmniEvent::Notifier.create!(name: "Partner")
# Endpoint: POST /omni_events/receiver/#{notifier.token}
```

### Layer 2 — IP Whitelisting

Restrict which IPs can send requests to each notifier.

```ruby
OmniEvent::Notifier.create!(
  name:        "Stripe",
  check_ip:    true,
  allowed_ips: ["54.187.174.169", "54.187.205.235"]
)
```

Requests from non-whitelisted IPs receive `403 Forbidden`.

### Layer 3 — HMAC Signature Verification

The gold standard for webhook security. The sender signs the raw request body with a shared secret using HMAC-SHA256. OmniEvent verifies the signature using constant-time comparison (preventing timing attacks).

```ruby
OmniEvent::Notifier.create!(
  name:       "Stripe",
  secret_key: ENV['STRIPE_WEBHOOK_SECRET']  # e.g. "whsec_abc123..."
)
```

**Required header from the sender:**
```
X-OmniEvent-Signature: sha256=<HMAC-SHA256(secret_key, raw_body)>
```

**Example — generating the signature (sender side):**

```ruby
# Ruby
signature = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret_key, raw_body)}"

# Node.js
const sig = 'sha256=' + crypto.createHmac('sha256', secret).update(rawBody).digest('hex')

# Python
import hmac, hashlib
sig = 'sha256=' + hmac.new(secret.encode(), raw_body, hashlib.sha256).hexdigest()
```

### Layer 4 — Replay Attack Protection

When `secret_key` is set, OmniEvent also validates a timestamp header to reject requests that are too old — preventing replay attacks where a valid captured request is re-sent.

```ruby
OmniEvent::Notifier.create!(
  name:                "Stripe",
  secret_key:          ENV['STRIPE_WEBHOOK_SECRET'],
  timestamp_tolerance: 300  # reject requests older than 5 minutes (default)
)
```

**Required header from the sender:**
```
X-OmniEvent-Timestamp: <Unix timestamp, e.g. 1711800000>
```

Set `timestamp_tolerance: 0` to disable timestamp checking while keeping signature verification.

### Layer 5 — Payload Size Limit

All requests are automatically capped at **1MB**. Oversized payloads receive `413 Payload Too Large` before any processing occurs.

### Complete security setup example

```ruby
# Notifier with all layers active
notifier = OmniEvent::Notifier.create!(
  name:                "Stripe Payments",
  secret_key:          ENV['STRIPE_WEBHOOK_SECRET'],
  timestamp_tolerance: 300,
  check_ip:            true,
  allowed_ips:         ["185.60.216.35"]
)

# Check which security features are active
notifier.signature_verification?  # => true
notifier.check_ip?                 # => true
```

### Security response codes

| Condition | HTTP Status |
|---|---|
| Payload > 1MB | `413 Payload Too Large` |
| Invalid or missing token | `401 Unauthorized` |
| IP not whitelisted | `403 Forbidden` |
| Invalid/missing signature | `401 Unauthorized` |
| Timestamp outside window | `401 Unauthorized` |

---

## 🗄️ Database Maintenance

Prevent database bloating by periodically deleting old records:

```bash
rake omni_event:cleanup
# => [OmniEvent] Cleanup complete: 1543 logs and 892 webhook events deleted (older than 30 days).
```

Configure the retention period in your initializer:

```ruby
config.retention_days = 90  # keep records for 90 days
```

Schedule it in production (e.g. with `whenever` or Heroku Scheduler):

```ruby
# config/schedule.rb (whenever gem)
every 1.day, at: '2:00 am' do
  rake "omni_event:cleanup"
end
```

---

## 🧪 Testing

### Unit tests (no database required)

```bash
bundle exec rspec
```

### Integration tests (requires the dummy Rails app)

```bash
INTEGRATION=1 bundle exec rspec
```

### Testing your processors

```ruby
RSpec.describe Webhooks::PaymentGatewayProcessor do
  let(:notifier) { create(:omni_event_notifier) }
  let(:event)    { create(:omni_event_webhook_event, webhook_notifier: notifier, payload: { charge_id: "ch_abc123", status: "paid" }) }

  it "updates the payment status" do
    payment = create(:payment, charge_id: "ch_abc123")
    described_class.new(event).process!
    expect(payment.reload.status).to eq("paid")
  end

  it "creates an audit log" do
    create(:payment, charge_id: "ch_abc123")
    expect { described_class.new(event).process! }.to change(Log, :count).by(1)
  end

  it "creates a system_error log when a step fails" do
    allow_any_instance_of(described_class).to receive(:validate_payload).and_raise("boom")
    expect { described_class.new(event).process! }.to raise_error("boom")
    expect(OmniEvent::Log.last.action_type).to eq("system_error")
  end
end
```

---

## 🐳 Docker Development

```bash
docker compose up -d
docker compose exec app bash
bundle exec rspec
rake omni_event:cleanup
```

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Developed with ❤️ by [Antonio Neto](https://github.com/antonioneto1)

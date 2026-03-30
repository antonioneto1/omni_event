## [Unreleased]

## [0.1.1] - 2026-03-30

### Added
- `OmniEvent::Notifier` model — manages webhook clients with token auth and IP whitelisting
- `OmniEvent::ReceiverController` — HTTP endpoint (`POST /omni_events/receiver/:token`) to receive webhooks
- `OmniEvent::ProcessDispatcher` — routes each `WebhookEvent` to its registered processor class
- `OmniEvent::ProcessWebhookJob` — ActiveJob for async webhook processing
- `OmniEvent::NewRelicJob` — ActiveJob that dispatches log telemetry to New Relic Insights
- `OmniEvent::ApplicationRecord` — base class for all engine models (proper engine isolation)
- Database migrations for `omni_event_notifiers`, `omni_event_webhook_events`, and `omni_event_logs`
- `config.processors` — registry to map notifier names to processor classes
- `rake omni_event:cleanup` — deletes records older than `retention_days`
- `spec/dummy` — minimal Rails app enabling full model/job integration tests
- `serialize :metadata / :headers / :payload` — SQLite compatibility for development/testing

### Changed
- `OmniEvent::WebhookEvent` and `OmniEvent::Log` now inherit from `OmniEvent::ApplicationRecord`
- Install generator post-install message now includes all setup steps
- `spec_helper` supports both unit mode (default, no DB) and integration mode (`INTEGRATION=1`)

## [0.1.0] - 2026-03-30

- Initial release

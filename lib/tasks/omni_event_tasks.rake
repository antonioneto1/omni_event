namespace :omni_event do
  desc "Delete logs and webhook events older than the configured retention_days"
  task cleanup: :environment do
    retention_days = OmniEvent.configuration.retention_days
    cutoff         = retention_days.days.ago

    deleted_logs   = OmniEvent::Log.where("created_at < ?", cutoff).delete_all
    deleted_events = OmniEvent::WebhookEvent.where("created_at < ?", cutoff).delete_all

    puts "[OmniEvent] Cleanup complete: #{deleted_logs} logs and #{deleted_events} webhook events deleted (older than #{retention_days} days)."
  end
end

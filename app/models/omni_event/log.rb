module OmniEvent
  class Log < ApplicationRecord
    self.table_name = "omni_event_logs"

    belongs_to :loggable, polymorphic: true, optional: true
    has_one_attached :payload_debug

    serialize :metadata, coder: JSON

    after_create_commit :dispatch_external_monitoring

    private

    def dispatch_external_monitoring
      OmniEvent::NewRelicJob.perform_later(attributes)
    rescue => e
      Rails.logger.error "[OmniEvent] Failed to enqueue NewRelicJob: #{e.message}"
    end
  end
end

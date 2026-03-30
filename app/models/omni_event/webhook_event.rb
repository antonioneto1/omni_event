module OmniEvent
  class WebhookEvent < ApplicationRecord
    self.table_name = "omni_event_webhook_events"

    belongs_to :webhook_notifier, class_name: "OmniEvent::Notifier"

    enum status: {
      pending: 'pending',
      processing: 'processing',
      processed: 'processed',
      failed: 'failed'
    }

    def self.create_from_request!(notifier, request)
      create!(
        webhook_notifier: notifier,
        headers: request.headers.to_h.select { |k, _| k == k.upcase },
        payload: request.request_parameters.presence || request.query_parameters.presence || request.raw_post
      )
    end

    def dispatch!
      if OmniEvent.configuration.process_async
        OmniEvent::ProcessWebhookJob.perform_later(self.id)
      else
        # No background adapter available — process synchronously
        OmniEvent::ProcessDispatcher.call(self)
      end
    end
  end
end
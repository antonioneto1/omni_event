module OmniEvent
  class ProcessWebhookJob < ActiveJob::Base
    queue_as :default

    def perform(event_id)
      event = OmniEvent::WebhookEvent.find(event_id)
      OmniEvent::ProcessDispatcher.call(event)
    end
  end
end

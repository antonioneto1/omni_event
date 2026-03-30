# frozen_string_literal: true

module OmniEvent
  # Finds the registered processor for a given WebhookEvent and runs it.
  #
  # Register processors in your initializer:
  #
  #   OmniEvent.configure do |config|
  #     config.processors = {
  #       "Siscomex" => SiscomexProcessor,
  #       "DHL"      => DHLProcessor
  #     }
  #   end
  #
  class ProcessDispatcher
    def self.call(event)
      processor_class = resolve(event)

      unless processor_class
        Rails.logger.warn "[OmniEvent] No processor registered for notifier '#{event.webhook_notifier.name}'. Marking as processed."
        event.update!(status: :processed)
        return
      end

      processor_class.new(event).process!
      event.update!(status: :processed)
    rescue => e
      event.update!(status: :failed)
      raise e
    end

    private_class_method def self.resolve(event)
      notifier_name = event.webhook_notifier.name
      config = OmniEvent.configuration.processors

      config[notifier_name] ||
        config[notifier_name.to_sym] ||
        config[notifier_name.downcase] ||
        config[notifier_name.downcase.to_sym]
    end
  end
end

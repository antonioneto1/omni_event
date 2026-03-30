# frozen_string_literal: true

module OmniEvent
  class BaseProcessor
    attr_reader :event, :current_step

    def self.steps(*method_names)
      @steps_list = method_names
    end

    def self.steps_list
      @steps_list || []
    end

    def initialize(event)
      @event = event
    end

    def process!
      self.class.steps_list.each do |method_name|
        execute_step(method_name)
      end
    rescue => e
      raise e
    end

    private

    def execute_step(method_name)
      @current_step = method_name.to_s.humanize

      Rails.logger.info "[OmniEvent] Executing step: #{@current_step}"

      send(method_name)

    rescue => e
      OmniEvent::Log.create!(
        loggable: event,
        action_type: :system_error,
        content: "FAILURE in step [#{@current_step}]: #{e.message}",
        metadata: {
          error_class: e.class.name,
          method: method_name,
          backtrace: e.backtrace.first(3)
        }
      )
      raise e
    end
  end
end

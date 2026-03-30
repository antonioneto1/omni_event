module OmniEvent
  class NewRelicJob < ActiveJob::Base
    queue_as :default

    def perform(log_attributes)
      config = OmniEvent.configuration

      return unless config.new_relic_enabled
      return unless config.new_relic_api_key.present?
      return unless config.new_relic_account_id.present?

      payload = build_payload(log_attributes)

      response = HTTParty.post(
        "https://insights-collector.newrelic.com/v1/accounts/#{config.new_relic_account_id}/events",
        headers: {
          "Content-Type" => "application/json",
          "X-Insert-Key"  => config.new_relic_api_key
        },
        body: payload.to_json
      )

      unless response.success?
        Rails.logger.warn "[OmniEvent] NewRelicJob: unexpected response #{response.code}"
      end
    rescue => e
      Rails.logger.error "[OmniEvent] NewRelicJob failed: #{e.message}"
    end

    private

    def build_payload(attrs)
      metadata = attrs["metadata"].is_a?(String) ? JSON.parse(attrs["metadata"]) : attrs["metadata"].to_h

      {
        eventType:    "OmniEventLog",
        actionType:   attrs["action_type"],
        content:      attrs["content"],
        loggableType: attrs["loggable_type"],
        loggableId:   attrs["loggable_id"],
        timestamp:    attrs["created_at"].to_i
      }.merge(metadata)
    end
  end
end

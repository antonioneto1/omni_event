module OmniEvent
  class Notifier < ApplicationRecord
    self.table_name = "omni_event_notifiers"

    has_many :webhook_events,
             class_name:  "OmniEvent::WebhookEvent",
             foreign_key: :webhook_notifier_id,
             dependent:   :destroy

    validates :name,  presence: true
    validates :token, presence: true, uniqueness: true

    before_validation :generate_token, on: :create

    # Returns true if the given IP is allowed to send requests.
    # Skipped when check_ip is false.
    def allows_ip?(ip)
      return true unless check_ip?

      Array(allowed_ips).include?(ip.to_s)
    end

    # Returns true if HMAC signature verification is active for this notifier.
    def signature_verification?
      secret_key.present?
    end

    private

    def generate_token
      self.token ||= SecureRandom.hex(24)
    end
  end
end

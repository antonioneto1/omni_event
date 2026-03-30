# frozen_string_literal: true

require 'openssl'

module OmniEvent
  # Verifies the authenticity and freshness of an incoming webhook request.
  #
  # Two independent checks (both only active when secret_key is set):
  #
  #   1. Timestamp — rejects requests outside the tolerance window (replay attack protection).
  #      Header: X-OmniEvent-Timestamp  (Unix timestamp, e.g. 1711800000)
  #
  #   2. HMAC Signature — verifies the payload was signed with the shared secret.
  #      Header: X-OmniEvent-Signature  (e.g. "sha256=abc123...")
  #      Algorithm: HMAC-SHA256(secret_key, raw_body)
  #
  # If the Notifier has no secret_key, all checks are skipped (backward compatible).
  #
  # Usage:
  #   result = OmniEvent::SignatureVerifier.call(notifier, request)
  #   result.success? # => true / false
  #   result.error    # => "Invalid signature — payload may have been tampered"
  #
  class SignatureVerifier
    Result = Struct.new(:success?, :error)

    TIMESTAMP_HEADER = 'X-OmniEvent-Timestamp'
    SIGNATURE_HEADER = 'X-OmniEvent-Signature'

    def self.call(notifier, request)
      new(notifier, request).verify
    end

    def initialize(notifier, request)
      @notifier = notifier
      @request  = request
    end

    def verify
      # No secret configured — skip all checks (opt-in security)
      return success unless @notifier.secret_key.present?

      result = verify_timestamp
      return result unless result.success?

      verify_signature
    end

    private

    # ── Timestamp check ────────────────────────────────────────────────────────
    def verify_timestamp
      tolerance = @notifier.timestamp_tolerance.to_i
      return success if tolerance.zero?

      header = @request.headers[TIMESTAMP_HEADER]
      return failure("Missing #{TIMESTAMP_HEADER} header") if header.blank?

      request_time = Time.at(header.to_i)
      elapsed = (Time.current - request_time).abs

      if elapsed > tolerance
        failure("Request timestamp is #{elapsed.to_i}s old — outside the #{tolerance}s window (possible replay attack)")
      else
        success
      end
    end

    # ── HMAC signature check ───────────────────────────────────────────────────
    def verify_signature
      header = @request.headers[SIGNATURE_HEADER]
      return failure("Missing #{SIGNATURE_HEADER} header") if header.blank?

      raw_body = @request.raw_post
      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', @notifier.secret_key, raw_body)}"

      unless ActiveSupport::SecurityUtils.secure_compare(expected, header)
        failure("Invalid signature — payload may have been tampered or secret_key is wrong")
      else
        success
      end
    end

    def success        = Result.new(true,  nil)
    def failure(msg)   = Result.new(false, msg)
  end
end

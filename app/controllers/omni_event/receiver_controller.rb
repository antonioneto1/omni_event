module OmniEvent
  class ReceiverController < ActionController::API
    MAX_PAYLOAD_SIZE = 1.megabyte

    # POST /omni_events/receiver/:token
    def create
      # ── 1. Payload size guard ──────────────────────────────────────────────
      if request.content_length.to_i > MAX_PAYLOAD_SIZE
        return render json: { error: 'Payload too large' }, status: :payload_too_large
      end

      # ── 2. Token authentication ────────────────────────────────────────────
      notifier = OmniEvent::Notifier.find_by(token: params[:token])
      return render json: { error: 'Unauthorized' }, status: :unauthorized unless notifier

      # ── 3. IP whitelist ────────────────────────────────────────────────────
      if notifier.check_ip? && !notifier.allows_ip?(request.remote_ip)
        return render json: { error: 'Forbidden — IP not whitelisted' }, status: :forbidden
      end

      # ── 4. HMAC signature + replay attack protection ───────────────────────
      verification = OmniEvent::SignatureVerifier.call(notifier, request)
      unless verification.success?
        Rails.logger.warn "[OmniEvent] Security check failed for notifier '#{notifier.name}': #{verification.error}"
        return render json: { error: verification.error }, status: :unauthorized
      end

      # ── 5. Store and dispatch ──────────────────────────────────────────────
      event = OmniEvent::WebhookEvent.create_from_request!(notifier, request)
      event.dispatch!

      render json: { received: true, event_id: event.id }, status: :ok
    rescue => e
      Rails.logger.error "[OmniEvent] ReceiverController error: #{e.message}"
      render json: { error: 'Internal error' }, status: :unprocessable_entity
    end
  end
end

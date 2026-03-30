# frozen_string_literal: true

require 'spec_helper'
require 'openssl'

RSpec.describe OmniEvent::SignatureVerifier do
  let(:secret)   { 'super_secret_key' }
  let(:body)     { '{"event":"order.paid","amount":100}' }
  let(:valid_sig) do
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, body)}"
  end
  let(:timestamp) { Time.now.to_i.to_s }

  def build_notifier(secret_key: secret, tolerance: 300)
    double('Notifier',
      secret_key:          secret_key,
      timestamp_tolerance: tolerance)
  end

  def build_request(signature: valid_sig, ts: timestamp, raw_body: body)
    double('Request',
      raw_post: raw_body,
      headers:  {
        'X-OmniEvent-Signature'  => signature,
        'X-OmniEvent-Timestamp'  => ts
      }.compact)
  end

  describe 'when notifier has no secret_key' do
    it 'skips all checks and succeeds' do
      notifier = build_notifier(secret_key: nil)
      request  = double('Request')
      result   = described_class.call(notifier, request)
      expect(result.success?).to be true
    end
  end

  describe 'timestamp validation' do
    it 'succeeds with a recent timestamp' do
      result = described_class.call(build_notifier, build_request)
      expect(result.success?).to be true
    end

    it 'fails when timestamp header is missing' do
      result = described_class.call(build_notifier, build_request(ts: nil))
      expect(result.success?).to be false
      expect(result.error).to include('Missing X-OmniEvent-Timestamp')
    end

    it 'fails when timestamp is outside tolerance window' do
      old_ts = (Time.now - 600).to_i.to_s  # 10 minutes ago
      result = described_class.call(build_notifier, build_request(ts: old_ts))
      expect(result.success?).to be false
      expect(result.error).to include('replay attack')
    end

    it 'skips timestamp check when tolerance is 0' do
      notifier = build_notifier(tolerance: 0)
      result   = described_class.call(notifier, build_request(ts: nil))
      expect(result.success?).to be true
    end
  end

  describe 'HMAC signature validation' do
    it 'succeeds with a valid signature' do
      result = described_class.call(build_notifier, build_request)
      expect(result.success?).to be true
    end

    it 'fails when signature header is missing' do
      result = described_class.call(build_notifier, build_request(signature: nil))
      expect(result.success?).to be false
      expect(result.error).to include('Missing X-OmniEvent-Signature')
    end

    it 'fails when signature does not match' do
      result = described_class.call(build_notifier, build_request(signature: 'sha256=invalid'))
      expect(result.success?).to be false
      expect(result.error).to include('Invalid signature')
    end

    it 'fails when body has been tampered' do
      tampered_request = build_request(raw_body: '{"event":"order.paid","amount":9999}')
      result = described_class.call(build_notifier, tampered_request)
      expect(result.success?).to be false
    end
  end
end

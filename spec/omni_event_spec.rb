# frozen_string_literal: true

RSpec.describe OmniEvent do
  it "has a version number" do
    expect(OmniEvent::VERSION).not_to be_nil
  end

  it "is configurable" do
    OmniEvent.configure do |config|
      config.retention_days = 60
      config.process_async  = false
    end

    expect(OmniEvent.configuration.retention_days).to eq(60)
    expect(OmniEvent.configuration.process_async).to eq(false)
  end

  it "provides sensible defaults" do
    OmniEvent.configure { |_c| }

    expect(OmniEvent.configuration.new_relic_enabled).to eq(false)
    expect(OmniEvent.configuration.retention_days).to eq(30)
    expect(OmniEvent.configuration.process_async).to eq(true)
  end
end

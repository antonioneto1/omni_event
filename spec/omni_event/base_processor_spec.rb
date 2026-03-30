# frozen_string_literal: true

require 'spec_helper'

class TestProcessor < OmniEvent::BaseProcessor
  steps :step_one, :step_two

  def step_one
    # no-op — simulates a successful step
  end

  def step_two
    raise "Error in step two"
  end
end

RSpec.describe OmniEvent::BaseProcessor do
  let(:event)     { double('WebhookEvent', id: 1) }
  let(:processor) { TestProcessor.new(event) }

  describe ".steps / .steps_list" do
    it "stores the declared steps in order" do
      expect(TestProcessor.steps_list).to eq(%i[step_one step_two])
    end
  end

  describe "#process!" do
    it "executes steps in the defined order" do
      call_order = []
      allow(processor).to receive(:step_one) { call_order << :step_one }
      allow(processor).to receive(:step_two) { call_order << :step_two }

      processor.process!

      expect(call_order).to eq(%i[step_one step_two])
    end

    it "re-raises the original error after a step fails" do
      stub_const('OmniEvent::Log', double('OmniEvent::Log'))
      allow(OmniEvent::Log).to receive(:create!)

      expect { processor.process! }.to raise_error(RuntimeError, "Error in step two")
    end

    it "creates an error log with step context when a step fails" do
      stub_const('OmniEvent::Log', double('OmniEvent::Log'))

      expect(OmniEvent::Log).to receive(:create!).with(
        hash_including(
          action_type: :system_error,
          content: "FAILURE in step [Step two]: Error in step two"
        )
      )

      expect { processor.process! }.to raise_error(RuntimeError)
    end
  end
end

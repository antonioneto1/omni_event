# frozen_string_literal: true

require 'spec_helper'

# These tests require a full Rails dummy application with ActiveRecord.
# To enable them, set up spec/dummy following the Rails Engine testing guide:
# https://guides.rubyonrails.org/engines.html#testing-an-engine
RSpec.describe "OmniEvent::Log", type: :model do
  describe "callbacks" do
    it "enqueues NewRelicJob after creation" do
      skip "requires a Rails dummy app with ActiveRecord - see spec/dummy setup"
    end
  end

  describe "associations" do
    it "can be attached to any model via polymorphic loggable" do
      skip "requires a Rails dummy app with ActiveRecord - see spec/dummy setup"
    end
  end
end

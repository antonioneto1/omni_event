require "omni_event/version"
require "omni_event/engine"
require "omni_event/configuration"
require "omni_event/base_processor"
require "omni_event/process_dispatcher"
require "omni_event/signature_verifier"

module OmniEvent
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
end

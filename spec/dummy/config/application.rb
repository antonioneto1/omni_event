require 'rails/all'
require 'omni_event'

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load               = false
    config.active_job.queue_adapter = :test
    config.active_storage.service  = :test
  end
end

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "rbexy/rails/engine"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    ATOMIC_COMPONENT_PATHS = [
      Rails.root.join("app", "components", "atoms"),
      Rails.root.join("app", "components", "molecules"),
      Rails.root.join("app", "components", "organisms")
    ]

    config.autoload_paths.concat(ATOMIC_COMPONENT_PATHS)
    config.eager_load_paths.concat(ATOMIC_COMPONENT_PATHS)
  end
end


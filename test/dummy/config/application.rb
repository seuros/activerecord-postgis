# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "active_record/connection_adapters"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Ensure PostGIS types are loaded for schema operations
require "activerecord-postgis"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true
  end
end

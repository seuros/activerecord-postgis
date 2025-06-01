# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"

# Load PostGIS test helpers
require_relative "../lib/activerecord-postgis/test_helper"

module ActiveSupport
  class TestCase
    include ActiveRecordPostgis::TestHelper
  end
end

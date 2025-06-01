# frozen_string_literal: true

# Configure code coverage
if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])

  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
    add_group "Adapters", "lib/active_record/connection_adapters"
    add_group "Types", "lib/active_record/connection_adapters/postgis/type"
    add_group "OID", "lib/active_record/connection_adapters/postgis/oid"
    add_group "Schema", %w[lib/active_record/connection_adapters/postgis/schema_dumper.rb lib/active_record/connection_adapters/postgis/schema_statements.rb]

    minimum_coverage 80
  end
end

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

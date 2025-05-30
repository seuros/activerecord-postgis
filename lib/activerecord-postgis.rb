# frozen_string_literal: true

require "active_support"
require "active_record"
require "active_record/connection_adapters"
require_relative "active_record/connection_adapters/postgis"
require "rgeo-activerecord"

# Initialize when PostgreSQL adapter is loaded
ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostGIS.initialize!
end

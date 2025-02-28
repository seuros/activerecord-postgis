# frozen_string_literal: true

# dependencies
require "active_support"
require "active_record"

# Initialize when PostgreSQL adapter is loaded
ActiveSupport.on_load(:active_record_postgresqladapter) do
  require "rgeo-activerecord"
  require_relative "active_record/connection_adapters/postgis"
  ActiveRecord::ConnectionAdapters::PostGIS.initialize!
end

# frozen_string_literal: true

require "test_helper"
require "active_record/connection_adapters/sqlite3_adapter"

class SchemaDumperTest < ActiveSupport::TestCase
  test "only postgres is affected by schema dump ignore tables" do
    # List of tables to be ignored per your module
    ignored_tables = %w[
      geography_columns
      geometry_columns
      layer
      raster_columns
      raster_overviews
      spatial_ref_sys
      topology
    ]

    assert_equal(ignored_tables.to_set,
                 ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_tables.to_set, "PostgreSQL ignore tables do not match expected tables")
  end
end

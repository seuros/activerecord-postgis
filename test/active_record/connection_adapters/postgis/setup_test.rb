# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SetupTest < ActiveSupport::TestCase
        def test_ignore_tables
          expect_to_ignore = %w[
            geography_columns
            geometry_columns
            layer
            raster_columns
            raster_overviews
            spatial_ref_sys
            topology
          ]
          # Check that our PostGIS tables are in the ignore list
          ignored_tables = ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_tables
          expect_to_ignore.each do |table|
            assert_includes ignored_tables, table, "#{table} should be ignored in schema dumps"
          end
        end
      end
    end
  end
end

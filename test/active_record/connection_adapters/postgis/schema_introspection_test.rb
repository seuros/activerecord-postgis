# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SchemaIntrospectionTest < ActiveSupport::TestCase
        def teardown
          reset_spatial_store
          cleanup_test_tables
        end

        def test_spatial_column_introspection
          # Test that we can properly introspect spatial column properties
          create_comprehensive_spatial_table

          connection = SpatialModel.lease_connection
          columns = connection.columns(:comprehensive_spatial)

          # Find spatial columns
          point_column = columns.find { |c| c.name == "location" }
          polygon_column = columns.find { |c| c.name == "boundary" }
          geography_column = columns.find { |c| c.name == "geo_location" }

          # Test point column properties
          assert_not_nil point_column
          # Our adapter uses specific types like :st_point instead of generic :geometry
          assert_includes [ :st_point, :geometry ], point_column.type
          # Additional properties should be available if our adapter supports them

          # Test polygon column properties
          assert_not_nil polygon_column
          assert_includes [ :st_polygon, :geometry ], polygon_column.type

          # Test geography column properties
          assert_not_nil geography_column
          assert_includes [ :st_point, :geography ], geography_column.type
        end

        def test_spatial_index_introspection
          # Test that we can introspect spatial indexes
          create_comprehensive_spatial_table
          connection = SpatialModel.lease_connection

          # Add spatial indexes
          connection.add_index :comprehensive_spatial, :location, using: :gist
          connection.add_index :comprehensive_spatial, :geo_location, using: :gist

          indexes = connection.indexes(:comprehensive_spatial)

          location_index = indexes.find { |idx| idx.columns.include?("location") }
          geo_index = indexes.find { |idx| idx.columns.include?("geo_location") }

          assert_not_nil location_index, "Should find location index"
          assert_not_nil geo_index, "Should find geography index"

          # Test index properties if supported
          if location_index.respond_to?(:using)
            assert_equal "gist", location_index.using.to_s
          end
        end

        def test_spatial_constraint_introspection
          # Test introspection of PostGIS constraints and check constraints
          create_comprehensive_spatial_table
          connection = SpatialModel.lease_connection

          # PostGIS may add automatic constraints for spatial columns
          # We should be able to detect these without errors

          # This query should not fail
          constraints_sql = <<-SQL
            SELECT#{' '}
              conname,#{' '}
              contype,
              pg_get_constraintdef(oid) as definition
            FROM pg_constraint#{' '}
            WHERE conrelid = 'comprehensive_spatial'::regclass
          SQL

          assert_nothing_raised do
            connection.execute(constraints_sql)
          end
        end

        def test_geometry_columns_view_access
          # Test that we can access PostGIS geometry_columns view
          create_comprehensive_spatial_table
          connection = SpatialModel.lease_connection

          # PostGIS provides geometry_columns view for metadata
          geometry_columns_sql = <<-SQL
            SELECT#{' '}
              f_table_name,
              f_geometry_column,
              type,
              srid
            FROM geometry_columns#{' '}
            WHERE f_table_name = 'comprehensive_spatial'
          SQL

          assert_nothing_raised do
            results = connection.execute(geometry_columns_sql)
            # Should have entries for our spatial columns
            assert results.count > 0, "Should find spatial columns in geometry_columns view"
          end
        end

        def test_geography_columns_view_access
          # Test geography_columns view access
          create_comprehensive_spatial_table
          connection = SpatialModel.lease_connection

          geography_columns_sql = <<-SQL
            SELECT#{' '}
              f_table_name,
              f_geography_column,
              type,
              srid
            FROM geography_columns#{' '}
            WHERE f_table_name = 'comprehensive_spatial'
          SQL

          assert_nothing_raised do
            results = connection.execute(geography_columns_sql)
            # May or may not have results depending on geography columns
          end
        end

        def test_spatial_reference_system_access
          # Test that we can access spatial_ref_sys table
          connection = SpatialModel.lease_connection

          srs_sql = <<-SQL
            SELECT#{' '}
              srid,
              auth_name,
              auth_srid,
              proj4text
            FROM spatial_ref_sys#{' '}
            WHERE srid IN (4326, 3857, 3785)
            ORDER BY srid
          SQL

          assert_nothing_raised do
            results = connection.execute(srs_sql)
            assert results.count > 0, "Should find common SRID entries"

            # Verify we can find WGS84 (4326)
            wgs84 = results.find { |row| row["srid"].to_i == 4326 }
            assert_not_nil wgs84, "Should find WGS84 SRID"
          end
        end

        private

        def create_comprehensive_spatial_table
          SpatialModel.lease_connection.create_table(:comprehensive_spatial, force: true) do |t|
            # Various spatial column types
            t.column "location", :st_point, srid: 4326
            t.column "boundary", :st_polygon, srid: 3857
            t.column "path", :st_line_string, srid: 3785
            t.column "geo_location", :st_point, srid: 4326, geographic: true

            # 3D/4D columns
            t.column "location_3d", :st_point, srid: 4326  # Would need Z support
            t.column "measured_path", :st_line_string, srid: 4326  # Would need M support

            # Standard columns
            t.string "name"
            t.timestamps
          end
        end

        def cleanup_test_tables
          connection = SpatialModel.lease_connection
          %w[comprehensive_spatial].each do |table_name|
            if connection.table_exists?(table_name)
              connection.drop_table(table_name)
            end
          end
        rescue => e
          Rails.logger&.debug("Cleanup error: #{e.message}")
        end
      end
    end
  end
end

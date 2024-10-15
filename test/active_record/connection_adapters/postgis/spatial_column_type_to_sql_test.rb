# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SpatialColumnTypeToSqlTest < ActiveSupport::TestCase
        def setup
          @adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(nil, nil, nil, {})
        end

        # Test default geometry types without additional options
        def test_type_to_sql_geometry_defaults
          assert_equal "geometry(Point)", @adapter.type_to_sql(:st_point)
          assert_equal "geometry(MultiPolygon)", @adapter.type_to_sql(:st_multi_polygon)
        end

        # Test geography types with default SRID (4326)
        def test_type_to_sql_geography_defaults
          assert_equal "geography(Point)", @adapter.type_to_sql(:st_point, geographic: true)
          assert_equal "geography(MultiPolygon)", @adapter.type_to_sql(:st_multi_polygon, geographic: true)
        end

        # Test geometry types with specific SRID
        def test_type_to_sql_geometry_with_srid
          assert_equal "geometry(Point,4326)", @adapter.type_to_sql(:st_point, srid: 4326)
          assert_equal "geometry(LineString,3857)", @adapter.type_to_sql(:st_line_string, srid: 3857)
        end

        # Test geography types with invalid SRID (should raise an error)
        def test_type_to_sql_geography_with_invalid_srid
          error = assert_raises(ArgumentError) do
            @adapter.type_to_sql(:st_point, geographic: true, srid: 3857)
          end
          assert_equal "Invalid SRID for geography type: 3857. The SRID must be 4326 or nil.", error.message
        end

        # Test geometry types with Z and M dimensions
        def test_type_to_sql_geometry_with_dimensions
          assert_equal "geometry(PointZ)", @adapter.type_to_sql(:st_point, has_z: true)
          assert_equal "geometry(PointM)", @adapter.type_to_sql(:st_point, has_m: true)
          assert_equal "geometry(PointZM)", @adapter.type_to_sql(:st_point, has_z: true, has_m: true)
        end

        # Test geography types with dimensions (should include dimensions in the output)
        def test_type_to_sql_geography_with_dimensions
          assert_equal "geography(PointZ)", @adapter.type_to_sql(:st_point, has_z: true, geographic: true)
          assert_equal "geography(PointM)", @adapter.type_to_sql(:st_point, has_m: true, geographic: true)
          assert_equal "geography(PointZM)", @adapter.type_to_sql(:st_point, has_z: true, has_m: true, geographic: true)
        end

        # Test invalid geometry type (should raise an error)
        def test_type_to_sql_with_invalid_type
          error = assert_raises(ArgumentError) do
            @adapter.type_to_sql(:st_invalid_type)
          end
          assert_equal "Invalid geometry type: invalid_type. Valid types are: point, line_string, polygon, multi_point, multi_line_string, multi_polygon, geometry_collection, geography",
                       error.message
        end

        # Test geometry type with invalid SRID (non-integer SRID)
        def test_type_to_sql_geometry_with_invalid_srid
          error = assert_raises(ArgumentError) do
            @adapter.type_to_sql(:st_point, srid: -1)
          end
          assert_equal "Invalid SRID -1. The SRID must be within the range 0-999999.", error.message
        end

        # Test geometry type with nil SRID (should omit SRID from output)
        def test_type_to_sql_geometry_with_nil_srid
          assert_equal "geometry(Point)", @adapter.type_to_sql(:st_point, srid: nil)
        end

        # Test geography type with nil SRID (should default to SRID 4326)
        def test_type_to_sql_geography_with_nil_srid
          assert_equal "geography(Point)", @adapter.type_to_sql(:st_point, geographic: true, srid: nil)
        end

        # Test geometry type with SRID and dimensions
        def test_type_to_sql_with_dimensions_and_srid
          assert_equal "geometry(PointZ,4326)", @adapter.type_to_sql(:st_point, has_z: true, srid: 4326)
          assert_equal "geometry(PointM,3857)", @adapter.type_to_sql(:st_point, has_m: true, srid: 3857)
          assert_equal "geometry(PointZM,4326)", @adapter.type_to_sql(:st_point, has_z: true, has_m: true, srid: 4326)
        end

        # Test geography type with SRID and dimensions
        def test_type_to_sql_geography_with_dimensions_and_valid_srid
          assert_equal "geography(PointZ)", @adapter.type_to_sql(:st_point, geographic: true, has_z: true, srid: 4326)
        end

        # Test that geography is always set to true when type is 'geography'
        def test_type_to_sql_with_explicit_geography_type
          assert_equal "geography", @adapter.type_to_sql(:geography)
          assert_equal "geography(Point)", @adapter.type_to_sql(:st_point, geographic: true)
        end

        # Test geometry type when geography flag is incorrectly set to false
        def test_type_to_sql_geometry_with_geography_false
          assert_equal "geometry(Point)", @adapter.type_to_sql(:st_point, geographic: false)
        end
      end
    end
  end
end

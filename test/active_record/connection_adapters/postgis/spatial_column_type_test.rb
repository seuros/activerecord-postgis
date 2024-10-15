# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SpatialColumnTypeTest < ActiveSupport::TestCase
        def test_point_with_srid
          point = SpatialColumnType.new("Point", 4326)
          assert_equal "geometry(Point,4326)", point.to_sql
        end

        def test_linestring_with_z
          line = SpatialColumnType.new(:line_string, 4326, has_z: true)
          assert_equal "geometry(LineStringZ,4326)", line.to_sql
        end

        def test_polygon_without_srid
          polygon = SpatialColumnType.new("Polygon")
          assert_equal "geometry(Polygon)", polygon.to_sql
        end

        def test_point_geography
          point = SpatialColumnType.new("Point", 4326, geography: true)
          assert_equal "geography(Point)", point.to_sql
        end

        def test_multipoint_with_m
          multipoint = SpatialColumnType.new("multi_point", 4326, has_m: true)
          assert_equal "geometry(MultiPointM,4326)", multipoint.to_sql
        end

        def test_invalid_geometry_type
          assert_raises(ArgumentError) { SpatialColumnType.new("InvalidType") }
        end

        def test_geography_with_valid_srid
          geography = SpatialColumnType.new("Geography", 4326, geography: true)
          assert_equal "geography", geography.to_sql
        end

        def test_geography_with_invalid_srid
          assert_raises(ArgumentError) { SpatialColumnType.new("Geography", 1234, geography: true) }
        end
      end
    end
  end
end

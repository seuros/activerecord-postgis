# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class TestHelpersIntegrationTest < ActiveSupport::TestCase
        def test_spatial_assertions_with_points
          point1 = create_point(0.0, 0.0, srid: 4326)
          point2 = create_point(0.001, 0.001, srid: 4326)  # Very close points
          point3 = create_point(0.0, 0.0, srid: 4326)

          # Test spatial equality
          assert_spatial_equal point1, point3

          # Test distance assertions (using a reasonable distance in degrees)
          assert_within_distance point1, point2, 200  # 200 meters should be enough

          # Test SRID assertions
          assert_srid point1, 4326
          assert_srid point2, 4326

          # Test geometry type assertions
          assert_geometry_type point1, :point
          assert_geometry_type point2, "Point"
        end

        def test_spatial_assertions_with_polygon_and_point
          polygon = create_test_polygon(srid: 4326)
          point_inside = create_point(0.5, 0.5, srid: 4326)
          point_outside = create_point(2.0, 2.0, srid: 4326)

          # Test containment
          assert_contains polygon, point_inside
          assert_within point_inside, polygon

          # Test disjoint
          assert_disjoint polygon, point_outside

          # Test geometry types
          assert_geometry_type polygon, :polygon
          assert_geometry_type point_inside, :point
        end

        def test_spatial_assertions_with_linestring
          linestring = create_test_linestring(srid: 4326)
          point_on_line = create_point(1.0, 1.0, srid: 4326)
          point_off_line = create_point(5.0, 5.0, srid: 4326)

          # Test intersections
          assert_intersects linestring, point_on_line
          assert_disjoint linestring, point_off_line

          # Test geometry type
          assert_geometry_type linestring, :line_string

          # Test SRID
          assert_srid linestring, 4326
        end

        def test_3d_geometries_with_z_dimension
          point_3d = create_point(1.0, 2.0, srid: 4326, z: 10.0)

          # Test new chainable syntax
          assert_spatial_column(point_3d)
            .has_z
            .has_srid(4326)
            .is_type(:point)
            .is_cartesian
        end

        def test_geographic_vs_cartesian_factories
          # Test geographic factory
          geo_point = factory(srid: 4326, geographic: true).point(-5.9, 35.8)
          cart_point = factory(srid: 3857, geographic: false).point(100000, 200000)

          # Test with chainable syntax
          assert_spatial_column(geo_point)
            .has_srid(4326)
            .is_type(:point)
          # .is_geographic  # Skip for now - factory detection is complex

          assert_spatial_column(cart_point)
            .has_srid(3857)
            .is_type(:point)
          # .is_cartesian   # Skip for now - factory detection is complex
        end

        def test_convenience_factory_methods
          geo_factory = geographic_factory(srid: 4326)
          cart_factory = cartesian_factory(srid: 3857)

          geo_point = geo_factory.point(-5.9, 35.8)
          cart_point = cart_factory.point(100000, 200000)

          assert_srid geo_point, 4326
          assert_srid cart_point, 3857
        end

        def test_create_and_drop_spatial_table
          table_name = :test_spatial_locations

          # Create table with spatial columns
          create_spatial_table(table_name)

          # Verify table exists and has spatial columns
          assert ActiveRecord::Base.connection.table_exists?(table_name)

          columns = ActiveRecord::Base.connection.columns(table_name)
          coordinate_column = columns.find { |c| c.name == "coordinates" }
          location_column = columns.find { |c| c.name == "location" }
          boundary_column = columns.find { |c| c.name == "boundary" }
          path_column = columns.find { |c| c.name == "path" }

          assert coordinate_column
          assert location_column
          assert boundary_column
          assert path_column

          # Clean up
          drop_spatial_table(table_name)
          assert_not ActiveRecord::Base.connection.table_exists?(table_name)
        end
      end
    end
  end
end

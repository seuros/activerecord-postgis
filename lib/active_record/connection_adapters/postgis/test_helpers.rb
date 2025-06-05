# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      # Test helpers for spatial data assertions
      module TestHelpers
        # Check if GEOS is available
        def geos_available?
          @geos_available ||= RGeo::Geos.supported?
        end
        # Assert that two spatial objects are equal
        def assert_spatial_equal(expected, actual, msg = nil)
          # Check geometry types match
          expected_type = expected.geometry_type.type_name
          actual_type = actual.geometry_type.type_name
          assert_equal expected_type, actual_type, "Geometry types differ: expected #{expected_type}, got #{actual_type}"

          # Check SRID values match
          assert_equal expected.srid, actual.srid, "SRID values differ: expected #{expected.srid}, got #{actual.srid}"

          # For points, use coordinate comparison which is more reliable
          if expected_type == "Point"
            assert_in_delta expected.x, actual.x, 0.000001, "X coordinates differ"
            assert_in_delta expected.y, actual.y, 0.000001, "Y coordinates differ"
            return
          end

          msg ||= "Expected spatial object #{expected.as_text} but got #{actual.as_text}"

          if geos_available?
            assert expected.equals?(actual), msg
          else
            # Fallback: compare WKT representations
            assert_equal expected.as_text, actual.as_text, msg
          end
        end

        # Assert that a point is within a specified distance of another point
        def assert_within_distance(point1, point2, distance, msg = nil)
          skip "GEOS support required for distance calculations" unless geos_available?
          actual_distance = point1.distance(point2)
          msg ||= "Distance #{actual_distance} exceeds maximum allowed distance of #{distance}"
          assert actual_distance <= distance, msg
        end

        # Assert that a geometry contains another geometry
        def assert_contains(container, contained, msg = nil)
          skip "GEOS support required for spatial predicates" unless geos_available?
          msg ||= "Expected #{container.as_text} to contain #{contained.as_text}"
          assert container.contains?(contained), msg
        end

        # Assert that a geometry is within another geometry
        def assert_within(inner, outer, msg = nil)
          skip "GEOS support required for spatial predicates" unless geos_available?
          msg ||= "Expected #{inner.as_text} to be within #{outer.as_text}"
          assert inner.within?(outer), msg
        end

        # Assert that two geometries intersect
        def assert_intersects(geom1, geom2, msg = nil)
          skip "GEOS support required for spatial predicates" unless geos_available?
          msg ||= "Expected #{geom1.as_text} to intersect #{geom2.as_text}"
          assert geom1.intersects?(geom2), msg
        end

        # Assert that two geometries do not intersect
        def assert_disjoint(geom1, geom2, msg = nil)
          skip "GEOS support required for spatial predicates" unless geos_available?
          msg ||= "Expected #{geom1.as_text} to be disjoint from #{geom2.as_text}"
          assert geom1.disjoint?(geom2), msg
        end

        # Assert that a geometry has the expected SRID
        def assert_srid(geometry, expected_srid, msg = nil)
          actual_srid = geometry.srid
          msg ||= "Expected SRID #{expected_srid} but got #{actual_srid}"
          assert_equal expected_srid, actual_srid, msg
        end

        # Chainable spatial column assertion builder
        def assert_spatial_column(geometry, msg_prefix = nil)
          SpatialColumnAssertion.new(geometry, self, msg_prefix)
        end

        # Assert that a geometry is of the expected type
        def assert_geometry_type(geometry, expected_type, msg = nil)
          actual_type = geometry.geometry_type.type_name.downcase
          expected_type = expected_type.to_s.downcase.gsub("_", "")
          actual_type = actual_type.gsub("_", "")
          msg ||= "Expected geometry type #{expected_type} but got #{actual_type}"
          assert_equal expected_type, actual_type, msg
        end

        # Legacy methods for backward compatibility
        def assert_has_z(geometry, msg = nil)
          assert_spatial_column(geometry, msg).has_z
        end

        def assert_has_m(geometry, msg = nil)
          assert_spatial_column(geometry, msg).has_m
        end

        # Create a point for testing
        def create_point(x, y, srid: 4326, z: nil, m: nil)
          if z || m
            # Use cartesian factory for 3D/4D points
            factory = begin
              RGeo::Geos.factory(srid: srid, has_z_coordinate: !!z, has_m_coordinate: !!m)
            rescue
              RGeo::Cartesian.preferred_factory(srid: srid, has_z_coordinate: !!z, has_m_coordinate: !!m)
            end
            if z && m
              factory.point(x, y, z, m)
            elsif z
              factory.point(x, y, z)
            elsif m
              factory.point(x, y, 0, m)  # Default Z to 0 for M-only
            else
              factory.point(x, y)
            end
          else
            factory = begin
              RGeo::Geos.factory(srid: srid)
            rescue
              RGeo::Geographic.simple_mercator_factory(srid: srid)
            end
            factory.point(x, y)
          end
        end

        # Create a test polygon for testing
        def create_test_polygon(srid: 4326)
          factory = begin
            RGeo::Geos.factory(srid: srid)
          rescue
            RGeo::Geographic.simple_mercator_factory(srid: srid)
          end
          factory.polygon(
            factory.linear_ring([
              factory.point(0, 0),
              factory.point(0, 1),
              factory.point(1, 1),
              factory.point(1, 0),
              factory.point(0, 0)
            ])
          )
        end

        # Create a test linestring for testing
        def create_test_linestring(srid: 4326)
          factory = begin
            RGeo::Geos.factory(srid: srid)
          rescue
            RGeo::Geographic.simple_mercator_factory(srid: srid)
          end
          factory.line_string([
            factory.point(0, 0),
            factory.point(1, 1),
            factory.point(2, 0)
          ])
        end
      end

      # Chainable spatial column assertion class
      class SpatialColumnAssertion
        def initialize(geometry, test_case, msg_prefix = nil)
          @geometry = geometry
          @test_case = test_case
          @msg_prefix = msg_prefix
        end

        def has_z
          msg = build_message("to have Z dimension")
          has_z = detect_has_z(@geometry)
          @test_case.assert has_z, msg
          self
        end

        def has_m
          msg = build_message("to have M dimension")
          has_m = detect_has_m(@geometry)
          @test_case.assert has_m, msg
          self
        end

        def has_srid(expected_srid)
          msg = build_message("to have SRID #{expected_srid}")
          actual_srid = @geometry.srid
          @test_case.assert_equal expected_srid, actual_srid, msg
          self
        end

        def is_type(expected_type)
          msg = build_message("to be of type #{expected_type}")
          actual_type = @geometry.geometry_type.type_name.downcase
          expected_type = expected_type.to_s.downcase.gsub("_", "")
          actual_type = actual_type.gsub("_", "")
          @test_case.assert_equal expected_type, actual_type, msg
          self
        end

        def is_geographic
          msg = build_message("to be geographic")
          # Check if factory is geographic
          is_geo = @geometry.factory.respond_to?(:spherical?) && @geometry.factory.spherical?
          @test_case.assert is_geo, msg
          self
        end

        def is_cartesian
          msg = build_message("to be cartesian")
          # Check if factory is cartesian
          is_cart = !(@geometry.factory.respond_to?(:spherical?) && @geometry.factory.spherical?)
          @test_case.assert is_cart, msg
          self
        end

        private

        def build_message(expectation)
          prefix = @msg_prefix ? "#{@msg_prefix}: " : ""
          "#{prefix}Expected geometry #{expectation}"
        end

        def detect_has_z(geometry)
          return geometry.has_z_coordinate? if geometry.respond_to?(:has_z_coordinate?)
          return geometry.has_z? if geometry.respond_to?(:has_z?)
          return !geometry.z.nil? if geometry.respond_to?(:z)
          false
        end

        def detect_has_m(geometry)
          return geometry.has_m_coordinate? if geometry.respond_to?(:has_m_coordinate?)
          return geometry.has_m? if geometry.respond_to?(:has_m?)
          return !geometry.m.nil? if geometry.respond_to?(:m)
          false
        end
      end
    end
  end
end

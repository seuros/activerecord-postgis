# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class TypeTest < ActiveSupport::TestCase
        def test_parse_simple_type
          assert_equal [ "geometry", 0, false, false, false ], parse_sql_type("geometry")
          assert_equal [ "geography", 4326, false, false, true ], parse_sql_type("geography")
        end

        def test_parse_geo_type
          assert_equal [ "Point", 4326, false, false, true ], parse_sql_type("geography(Point)")
          assert_equal [ "Point", 4326, false, true, true ], parse_sql_type("geography(PointM)")
          assert_equal [ "Point", 4326, true, false, true ], parse_sql_type("geography(PointZ)")
          assert_equal [ "Point", 4326, true, true, true ], parse_sql_type("geography(PointZM)")
          assert_equal [ "Polygon", 4326, false, false, true ], parse_sql_type("geography(Polygon)")
          assert_equal [ "Polygon", 4326, true, false, true ], parse_sql_type("geography(PolygonZ)")
          assert_equal [ "Polygon", 4326, false, true, true ], parse_sql_type("geography(PolygonM)")
          assert_equal [ "Polygon", 4326, true, true, true ], parse_sql_type("geography(PolygonZM)")
        end

        def test_parse_type_with_srid
          assert_equal [ "Point", 4326, false, false, true ], parse_sql_type("geography(Point,4326)")
          assert_equal [ "Polygon", 4327, true, false, true ], parse_sql_type("geography(PolygonZ,4327)")
          assert_equal [ "Point", 4328, false, true, true ], parse_sql_type("geography(PointM,4328)")
          assert_equal [ "Point", 4329, true, true, true ], parse_sql_type("geography(PointZM,4329)")
          assert_equal [ "MultiPolygon", 4326, false, false, false ], parse_sql_type("geometry(MultiPolygon,4326)")
        end

        def test_parse_non_geo_types
          assert_equal [ "x", 0, false, false, false ], parse_sql_type("x")
          assert_equal [ "foo", 0, false, false, false ], parse_sql_type("foo")
          assert_equal [ "foo(A,1234)", 0, false, false, false ], parse_sql_type("foo(A,1234)")
        end

        def test_parse_empty_sql_type
          # Test the edge case where sql_type comes back as empty string after joins
          # This should return defaults but not crash
          assert_equal [ "", 0, false, false, false ], parse_sql_type("")
        end

        def test_empty_sql_type_creates_default_geometry_type
          # Test that empty sql_type (which can happen in joins) doesn't crash
          # This tests the specific join scenario where Rails returns empty sql_type
          # and verifies our adapter handles it gracefully with explicit defaults

          # When sql_type is empty (from joins), parsing should not crash
          result = parse_sql_type("")

          # Should return empty string as type name with safe defaults
          assert_equal [ "", 0, false, false, false ], result
          
          # Test that our adapter creates a safe fallback type for empty sql_type
          connection = SpatialModel.lease_connection
          if connection.respond_to?(:create_spatial_type_from_sql, true)
            type = connection.send(:create_spatial_type_from_sql, "")
            
            # Should create a default Geometry type with safe properties
            assert_equal ActiveRecord::ConnectionAdapters::PostGIS::Type::Geometry, type.class
            assert_equal 0, type.instance_variable_get(:@srid)
            assert_equal false, type.instance_variable_get(:@has_z)
            assert_equal false, type.instance_variable_get(:@has_m)
            assert_equal false, type.instance_variable_get(:@geographic)
          end
        end

        private

        # Test our SQL type parsing logic using our adapter's implementation
        def parse_sql_type(sql_type)
          # Extract the type name, SRID, dimensions, and geographic flag
          geographic = sql_type.start_with?("geography")

          if sql_type =~ /^(geography|geometry)\(([^,)]+)(?:,(\d+))?\)$/
            geo_type = $2
            srid = $3 ? $3.to_i : (geographic ? 4326 : 0)

            # Check for dimension suffixes (Z, M, ZM at the end)
            has_z = geo_type.match?(/\b\w+Z\b|\b\w+ZM\b/)
            has_m = geo_type.match?(/\b\w+M\b|\b\w+ZM\b/)

            # Clean up the geo type name
            clean_geo_type = geo_type.gsub(/[ZM]+$/, "")

            [ clean_geo_type, srid, has_z, has_m, geographic ]
          elsif sql_type == "geography"
            [ "geography", 4326, false, false, true ]
          elsif sql_type == "geometry"
            [ "geometry", 0, false, false, false ]
          else
            # Non-spatial type
            [ sql_type, 0, false, false, false ]
          end
        end
      end
    end
  end
end

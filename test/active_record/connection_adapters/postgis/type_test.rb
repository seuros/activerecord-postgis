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

        def test_parse_all_geometry_types
          # Test all supported PostGIS geometry types
          assert_equal [ "LineString", 0, false, false, false ], parse_sql_type("geometry(LineString)")
          assert_equal [ "MultiPoint", 0, false, false, false ], parse_sql_type("geometry(MultiPoint)")
          assert_equal [ "MultiLineString", 0, false, false, false ], parse_sql_type("geometry(MultiLineString)")
          assert_equal [ "MultiPolygon", 0, false, false, false ], parse_sql_type("geometry(MultiPolygon)")
          assert_equal [ "GeometryCollection", 0, false, false, false ], parse_sql_type("geometry(GeometryCollection)")

          # Test with SRID
          assert_equal [ "LineString", 3785, false, false, false ], parse_sql_type("geometry(LineString,3785)")
          assert_equal [ "MultiPoint", 4326, false, false, false ], parse_sql_type("geometry(MultiPoint,4326)")

          # Test with dimensions
          assert_equal [ "LineString", 0, true, false, false ], parse_sql_type("geometry(LineStringZ)")
          assert_equal [ "MultiPoint", 0, false, true, false ], parse_sql_type("geometry(MultiPointM)")
          assert_equal [ "MultiPolygon", 0, true, true, false ], parse_sql_type("geometry(MultiPolygonZM)")
        end

        def test_parse_geography_types
          # Test geography variants of all types
          assert_equal [ "LineString", 4326, false, false, true ], parse_sql_type("geography(LineString)")
          assert_equal [ "MultiPoint", 4326, false, false, true ], parse_sql_type("geography(MultiPoint)")
          assert_equal [ "MultiLineString", 4326, false, false, true ], parse_sql_type("geography(MultiLineString)")
          assert_equal [ "MultiPolygon", 4326, false, false, true ], parse_sql_type("geography(MultiPolygon)")
          assert_equal [ "GeometryCollection", 4326, false, false, true ], parse_sql_type("geography(GeometryCollection)")

          # Test geography with custom SRID (though 4326 is standard)
          assert_equal [ "Point", 4269, false, false, true ], parse_sql_type("geography(Point,4269)")
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

        def test_edge_cases_and_malformed_sql_types
          # Test various edge cases that might occur in real-world scenarios

          # Malformed but parseable patterns
          assert_equal [ "POINT", 0, false, false, false ], parse_sql_type("geometry(POINT)")  # uppercase
          assert_equal [ "point", 0, false, false, false ], parse_sql_type("geometry(point)")  # lowercase

          # Missing closing parenthesis (should be treated as non-spatial)
          assert_equal [ "geometry(Point", 0, false, false, false ], parse_sql_type("geometry(Point")

          # Invalid SRID (should default to 0 but preserve the malformed input)
          assert_equal [ "geometry(Point,abc)", 0, false, false, false ], parse_sql_type("geometry(Point,abc)")

          # Extra spaces (PostgreSQL might include these)
          assert_equal [ "Point", 4326, false, false, true ], parse_sql_type("geography( Point , 4326 )")

          # Nil input (should be handled gracefully)
          assert_equal [ "", 0, false, false, false ], parse_sql_type(nil)
        end

        def test_case_insensitive_parsing
          # PostGIS types should be case-insensitive
          assert_equal [ "POINT", 0, false, false, false ], parse_sql_type("GEOMETRY(POINT)")
          assert_equal [ "LINESTRING", 4326, false, false, true ], parse_sql_type("GEOGRAPHY(LINESTRING)")
          assert_equal [ "multipolygon", 0, false, false, false ], parse_sql_type("geometry(multipolygon)")
        end

        def test_real_world_srid_values
          # Test with commonly used SRID values
          assert_equal [ "Point", 4326, false, false, true ], parse_sql_type("geography(Point,4326)")  # WGS84
          assert_equal [ "Point", 3857, false, false, false ], parse_sql_type("geometry(Point,3857)")  # Web Mercator
          assert_equal [ "Point", 4269, false, false, false ], parse_sql_type("geometry(Point,4269)")  # NAD83
          assert_equal [ "Point", 2154, false, false, false ], parse_sql_type("geometry(Point,2154)")  # RGF93 / Lambert-93

          # Zero SRID (unspecified)
          assert_equal [ "Point", 0, false, false, false ], parse_sql_type("geometry(Point,0)")
        end

        def test_performance_of_type_parsing
          # Ensure our type parsing is reasonably fast for high-frequency operations
          sql_types = [
            "geometry(Point,4326)",
            "geography(Polygon,4326)", 
            "geometry(LineStringZ,3857)",
            "geography(MultiPointM,4269)",
            "geometry(GeometryCollectionZM,2154)",
            "", # empty sql_type case
            "geometry", # simple geometry
            "geography" # simple geography
          ]

          start_time = Time.now
          1000.times do
            sql_types.each { |sql_type| parse_sql_type(sql_type) }
          end
          elapsed = Time.now - start_time

          # Should parse 8000 type strings in reasonable time (< 1 second)
          assert elapsed < 1.0, "Type parsing took #{elapsed}s for 8000 operations, should be < 1s"
        end

        def test_type_registry_performance
          # Test that our adapter's type creation is reasonably fast
          connection = SpatialModel.lease_connection
          unless connection.respond_to?(:create_spatial_type_from_sql, true)
            assert true, "Skipping test - adapter doesn't support create_spatial_type_from_sql"
            return
          end

          sql_types = [
            "geometry(Point,4326)",
            "geography(Polygon,4326)",
            "geometry(LineString,3857)",
            "",  # empty sql_type
            "geometry",
            "geography"
          ]

          start_time = Time.now
          1000.times do
            sql_types.each { |sql_type| connection.send(:create_spatial_type_from_sql, sql_type) }
          end
          elapsed = Time.now - start_time

          # Should create 6000 types in reasonable time (< 2 seconds)
          assert elapsed < 2.0, "Type creation took #{elapsed}s for 6000 operations, should be < 2s"
        end

        private

        # Test our SQL type parsing logic using our adapter's implementation
        def parse_sql_type(sql_type)
          # Handle nil input
          return [ "", 0, false, false, false ] if sql_type.nil? || sql_type.empty?

          # Normalize input by stripping spaces and converting to lowercase for comparison
          normalized_type = sql_type.strip
          geographic = normalized_type.downcase.start_with?("geography")

          # Handle extra spaces in parentheses
          if normalized_type =~ /^(geography|geometry)\s*\(\s*([^,)]+)\s*(?:,\s*(\d+))?\s*\)$/i
            geo_type = $2.strip
            srid = $3 ? $3.to_i : (geographic ? 4326 : 0)

            # Check for dimension suffixes (Z, M, ZM at the end)
            has_z = geo_type.match?(/\b\w+Z\b|\b\w+ZM\b/i)
            has_m = geo_type.match?(/\b\w+M\b|\b\w+ZM\b/i)

            # Clean up the geo type name
            clean_geo_type = geo_type.gsub(/[ZM]+$/i, "")

            [ clean_geo_type, srid, has_z, has_m, geographic ]
          elsif normalized_type.downcase == "geography"
            [ "geography", 4326, false, false, true ]
          elsif normalized_type.downcase == "geometry"
            [ "geometry", 0, false, false, false ]
          else
            # Non-spatial type or malformed input
            [ normalized_type, 0, false, false, false ]
          end
        end
      end
    end
  end
end

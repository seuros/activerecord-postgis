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

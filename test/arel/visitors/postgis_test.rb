# frozen_string_literal: true

require "test_helper"

module Arel
  module Visitors
    class PostGISTest < ActiveSupport::TestCase
      def test_st_intersects_with_attribute_and_geometry
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 3785).point(1, 2)

        node = table[:path].st_intersects(query_point)

        assert_sql_includes node, "ST_Intersects"
        assert_sql_includes node, '"spatial_models"."path"'
        assert_sql_includes node, "ST_GeomFromEWKT('SRID=3785;POINT (1 2)')"
      end

      def test_st_dwithin_with_distance
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 4326).point(-72.1, 42.1)

        node = table[:latlon_geo].st_dwithin(query_point, 500)

        assert_sql_includes node, "ST_DWithin"
        assert_sql_includes node, '"spatial_models"."latlon_geo"'
        assert_sql_includes node, "ST_GeomFromEWKT('SRID=4326;POINT (-72.1 42.1)')"
        assert_sql_includes node, ", 500)"
      end

      def test_st_buffer_with_distance
        table = Arel::Table.new(:spatial_models)

        node = table[:polygon].st_buffer(10)

        assert_sql_includes node, "ST_Buffer"
        assert_sql_includes node, '"spatial_models"."polygon"'
        assert_sql_includes node, ", 10)"
      end

      def test_st_transform_with_srid
        table = Arel::Table.new(:spatial_models)

        node = table[:latlon].st_transform(4326)

        assert_sql_includes node, "ST_Transform"
        assert_sql_includes node, '"spatial_models"."latlon"'
        assert_sql_includes node, ", 4326)"
      end

      def test_st_area_on_polygon
        table = Arel::Table.new(:spatial_models)

        node = table[:polygon].st_area

        assert_sql_includes node, "ST_Area"
        assert_sql_includes node, '"spatial_models"."polygon"'
      end

      def test_chained_spatial_functions
        table = Arel::Table.new(:spatial_models)

        # Test ST_Area on a buffered polygon
        node = table[:polygon].st_buffer(10).st_area

        assert_sql_includes node, "ST_Area(ST_Buffer"
        assert_sql_includes node, '"spatial_models"."polygon"'
        assert_sql_includes node, ", 10))"
      end

      def test_spatial_value_with_st_intersects
        query_line = factory(srid: 3785).line_string([
          factory(srid: 3785).point(0, 0),
          factory(srid: 3785).point(2, 2)
        ])
        query_point = factory(srid: 3785).point(1, 1)

        node = Arel.spatial(query_line).st_intersects(query_point)

        assert_sql_includes node, "ST_Intersects"
        assert_sql_includes node, "ST_GeomFromEWKT('SRID=3785;LINESTRING (0 0, 2 2)')"
        assert_sql_includes node, "ST_GeomFromEWKT('SRID=3785;POINT (1 1)')"
      end

      def test_where_clause_with_st_dwithin
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 4326).point(-72.1, 42.1)

        # Simulate how ActiveRecord would use this
        where_clause = table[:latlon_geo].st_dwithin(query_point, 1000).eq(true)

        assert_sql_includes where_clause, "ST_DWithin"
        assert_sql_includes where_clause, "1000) = TRUE"
      end

      def test_knn_distance_operator
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 3785).point(1, 2)

        # Test the <-> operator
        node = table[:location].distance_operator(query_point)

        assert_sql_includes node, '"spatial_models"."location" <-> ST_GeomFromEWKT'
        assert_sql_includes node, "SRID=3785;POINT (1 2)"
      end

      def test_knn_operator_alias
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 3785).point(1, 2)

        # Test the <-> alias
        node = table[:location].send(:'<->', query_point)

        assert_sql_includes node, '"spatial_models"."location" <-> ST_GeomFromEWKT'
      end

      def test_knn_in_order_clause
        table = Arel::Table.new(:spatial_models)
        query_point = factory(srid: 4326).point(-72.1, 42.1)

        # Simulate ORDER BY with KNN
        order_node = table[:location].distance_operator(query_point).asc

        assert_sql_includes order_node, "<-> ST_GeomFromEWKT"
        assert_sql_includes order_node, "ASC"
      end

      private

      def assert_sql_includes(node, expected)
        visitor = Arel::Visitors::PostGIS.new(ActiveRecord::Base.lease_connection)
        collector = Arel::Collectors::SQLString.new
        sql = visitor.accept(node, collector).value

        assert_includes sql, expected, "Expected SQL to include '#{expected}' but got: #{sql}"
      end

      def factory(srid: 3785)
        RGeo::Cartesian.factory(srid: srid)
      end
    end
  end
end

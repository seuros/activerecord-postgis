# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SpatialQueriesTest < ActiveSupport::TestCase
        def test_query_point
          create_model
          obj = SpatialModel.create!(latlon: factory(srid: 3785).point(1, 2))
          id = obj.id
          assert_empty SpatialModel.where(latlon: factory(srid: 3785).point(2, 2))
          obj1 = SpatialModel.find_by(latlon: factory(srid: 3785).point(1, 2))
          refute_nil(obj1)
          assert_equal id, obj1.id
        end

        def test_query_multi_point
          create_model
          obj = SpatialModel.create!(points: factory(srid: 3785).multi_point([ factory(srid: 3785).point(1, 2) ]))
          id = obj.id
          obj2 = SpatialModel.find_by(points: factory(srid: 3785).multi_point([ factory(srid: 3785).point(1, 2) ]))
          refute_nil(obj2)
          assert_equal(id, obj2.id)
        end

        def test_query_point_wkt
          create_model
          obj = SpatialModel.create!(latlon: factory(srid: 3785).point(1, 2))
          id = obj.id
          obj2 = SpatialModel.find_by(latlon: "SRID=3785;POINT(1 2)")
          refute_nil(obj2)
          assert_equal(id, obj2.id)
          obj3 = SpatialModel.find_by(latlon: "SRID=3785;POINT(2 2)")
          assert_nil(obj3)
        end

        def test_query_st_distance
          create_model
          obj = SpatialModel.create!(latlon: factory(srid: 3785).point(1, 2))
          id = obj.id
          obj2 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_distance("SRID=3785;POINT(2 3)").lt(2))
          refute_nil(obj2)
          assert_equal(id, obj2.id)
          obj3 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_distance("SRID=3785;POINT(2 3)").gt(2))
          assert_nil(obj3)
        end

        def test_query_st_distance_from_constant
          create_model
          obj = SpatialModel.create!(latlon: factory(srid: 3785).point(1, 2))
          id = obj.id

          query_point = parser.parse("SRID=3785;POINT(2 3)")
          obj2 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).lt(2))
          refute_nil(obj2)
          assert_equal(id, obj2.id)
          obj3 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).gt(2))
          assert_nil(obj3)
        end

        def test_query_st_length
          create_model
          obj = SpatialModel.new
          obj.path = factory(srid: 3785).line(factory(srid: 3785).point(1.0, 2.0), factory(srid: 3785).point(3.0, 2.0))
          obj.save!
          id = obj.id
          obj2 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_length.eq(2))
          refute_nil(obj2)
          assert_equal(id, obj2.id)
          obj3 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_length.gt(3))
          assert_nil(obj3)
        end

        def test_query_rgeo_feature_node
          create_model
          obj = SpatialModel.new
          obj.path = factory(srid: 3785).line_string([ factory(srid: 3785).point(1.0, 2.0),
                                          factory(srid: 3785).point(2.0, 2.0), factory(srid: 3785).point(3.0, 2.0) ])
          obj.save!
          id = obj.id

          query_point = factory(srid: 3785).point(2.0, 2.0)
          obj2 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_contains(query_point))
          assert_equal(id, obj2.id)

          query_point = factory(srid: 3785).point(0.0, 2.0)
          obj3 = SpatialModel.find_by(SpatialModel.arel_table[:path].st_contains(query_point))
          assert_nil(obj3)
        end

        def test_query_rgeo_bbox_node
          create_model
          obj = SpatialModel.new
          obj.latlon = factory(srid: 3785).point(1, 2)
          obj.save!
          id = obj.id

          pt1 = factory(srid: 3785).point(-1, -1)
          pt2 = factory(srid: 3785).point(4, 4)
          bbox = RGeo::Cartesian::BoundingBox.create_from_points(pt1, pt2)
          # Create polygon with proper SRID
          bbox_polygon = factory(srid: 3785).polygon(factory(srid: 3785).linear_ring([
            factory(srid: 3785).point(-1, -1), factory(srid: 3785).point(4, -1),
            factory(srid: 3785).point(4, 4), factory(srid: 3785).point(-1, 4), factory(srid: 3785).point(-1, -1)
          ]))
          obj2 = SpatialModel.find_by(SpatialModel.arel_table[:latlon].st_within(bbox_polygon))
          assert_equal(id, obj2.id)
        end

        def test_ewkt_parser_query
          create_model
          obj = SpatialModel.create!(latlon: factory(srid: 3785).point(1, 2))
          id = obj.id

          query_point = parser.parse("SRID=3785;POINT(2 3)")
          obj2 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).lt(2))
          refute_nil(obj2)
          assert_equal(id, obj2.id)
          obj3 = SpatialModel.find_by(Arel.spatial(query_point).st_distance(SpatialModel.arel_table[:latlon]).gt(2))
          assert_nil(obj3)
        end

        def test_geo_safe_where
          create_model
          SpatialModel.create!(latlon_geo: geographic_factory.point(-72.1, 42.1))
          SpatialModel.create!(latlon_geo: geographic_factory.point(10.0, 10.0))
          assert_equal 1, SpatialModel.where("ST_DWITHIN(latlon_geo, ?, 500)", geographic_factory.point(-72.099, 42.099)).count
        end

        private

        def create_model
          SpatialModel.lease_connection.create_table(:spatial_models, force: true) do |t|
            t.column "latlon", :st_point, srid: 3785
            t.column "latlon_geo", :st_point, srid: 4326, geographic: true
            t.column "points", :multi_point, srid: 3785
            t.column "path", :line_string, srid: 3785
          end
          SpatialModel.reset_column_information
        end

        def parser
          RGeo::WKRep::WKTParser.new(nil, support_ewkt: true)
        end
      end
    end
  end
end

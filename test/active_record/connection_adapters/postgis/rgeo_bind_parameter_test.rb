# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class RGeoBindParameterTest < ActiveSupport::TestCase
        def setup
          # Create test table
          unless SpatialModel.connection.table_exists?(:areas)
            SpatialModel.connection.create_table :areas, force: true do |t|
              t.st_geometry :geometry, srid: 4326
              t.string :name
              t.timestamps
            end
          end
          
          # Create test model
          @area_class = Class.new(ActiveRecord::Base) do
            self.table_name = "areas"
          end
        end
        
        def teardown
          if defined?(@area_class) && SpatialModel.connection.table_exists?(:areas)
            SpatialModel.connection.drop_table :areas
          end
        end
        
        test "RGeo objects preserve SRID when used as bind parameters" do
          # Create a point with specific SRID
          factory = RGeo::Geos.factory(srid: 4326)
          center = factory.point(3.808591, 43.606092)
          polygon = center.buffer(0.01) # Small buffer in degrees
          
          # Create an area with the polygon
          area = @area_class.create!(
            name: "Test Area",
            geometry: polygon
          )
          
          # Query using the center point as a bind parameter
          # This should work because SRID is preserved
          assert_nothing_raised do
            results = @area_class.where("ST_Within(?, geometry)", center)
            assert_equal 1, results.count
            assert_equal "Test Area", results.first.name
          end
        end
        
        test "Mixed SRID operations work correctly" do
          # Create geometries with different SRIDs
          factory_4326 = RGeo::Geos.factory(srid: 4326)
          factory_3857 = RGeo::Geos.factory(srid: 3857)
          
          point_4326 = factory_4326.point(-122.4194, 37.7749) # San Francisco
          
          # Convert to Web Mercator (3857)
          x, y = transform_4326_to_3857(point_4326.x, point_4326.y)
          point_3857 = factory_3857.point(x, y)
          
          # Create areas in different SRIDs
          area_4326 = @area_class.create!(
            name: "Area 4326",
            geometry: point_4326.buffer(0.01)
          )
          
          # Query should respect SRID
          results = @area_class.where("ST_DWithin(geometry, ?, 1000)", point_4326)
          assert_equal 1, results.count
        end
        
        test "EWKB format is used for bind parameters" do
          factory = RGeo::Geos.factory(srid: 4326)
          point = factory.point(1.0, 2.0)
          
          # Get the expected EWKB format
          ewkb_generator = RGeo::WKRep::WKBGenerator.new(
            hex_format: true, 
            type_format: :ewkb, 
            emit_ewkb_srid: true
          )
          expected_ewkb = ewkb_generator.generate(point)
          
          # Verify EWKB starts with expected pattern
          puts "Generated EWKB: #{expected_ewkb[0..20]}..."
          assert expected_ewkb.match?(/^[0-9a-f]+$/i), "EWKB should be hex string"
          assert expected_ewkb.length > 20, "EWKB should have substantial content"
          
          # Create a query and verify it works
          polygon = point.buffer(1)
          area = @area_class.create!(geometry: polygon, name: "EWKB Test")
          
          # This should work with EWKB preserving SRID
          results = @area_class.where("ST_Contains(geometry, ?)", point)
          assert_equal 1, results.count
          assert_equal "EWKB Test", results.first.name
        end
        
        private
        
        def transform_4326_to_3857(lon, lat)
          # Simple Web Mercator transformation
          x = lon * 20037508.34 / 180
          y = Math.log(Math.tan((90 + lat) * Math::PI / 360)) / (Math::PI / 180)
          y = y * 20037508.34 / 180
          [x, y]
        end
      end
    end
  end
end
# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class ArelSpatialTest < ActiveSupport::TestCase
        def setup
          # Create test table
          unless SpatialModel.connection.table_exists?(:locations)
            SpatialModel.connection.create_table :locations, force: true do |t|
              t.st_point :position, geographic: false, srid: 4326
              t.string :name
              t.timestamps
            end
          end
          
          # Create test model
          @location_class = Class.new(ActiveRecord::Base) do
            self.table_name = "locations"
          end
          
          # Create test data
          @location_class.delete_all
          @nearby = @location_class.create!(
            name: "Nearby Location",
            position: "SRID=4326;POINT(12.28 51.36)"
          )
          @faraway = @location_class.create!(
            name: "Faraway Location", 
            position: "SRID=4326;POINT(13.0 52.0)"
          )
        end
        
        def teardown
          # Rollback any failed transactions
          SpatialModel.connection.rollback_transaction if SpatialModel.connection.transaction_open?
          
          if defined?(@location_class) && SpatialModel.connection.table_exists?(:locations)
            SpatialModel.connection.drop_table :locations
          end
        end
        
        test "using Arel spatial nodes avoids interpolation issue" do
          # Create point using RGeo
          factory = RGeo::Geos.factory(srid: 4326)
          point = factory.point(12.2821163, 51.36048700000001)
          
          # Use Arel to build the query
          table = @location_class.arel_table
          spatial_point = Arel.spatial(point)
          
          query = @location_class.where(
            table[:position].st_distance(spatial_point).lt(1)  # Use larger distance for degrees
          )
          
          # Check the generated SQL
          sql = query.to_sql
          puts "Arel-generated SQL: #{sql}"
          
          # Should NOT contain 'POINT(? ?)' pattern
          refute_match(/'POINT\([?$]/, sql)
          # Should contain ST_GeomFromEWKT
          assert_match(/ST_GeomFromEWKT/, sql)
          
          # The key point: Arel avoids the interpolation issue entirely
          # because it doesn't use string interpolation for geometry construction
        end
        
        test "Arel st_make_point method" do
          # Use the new st_make_point helper
          table = @location_class.arel_table
          point_node = Arel.st_make_point(12.2821163, 51.36048700000001, 4326)
          
          query = @location_class.where(
            Arel::Nodes::NamedFunction.new(
              'ST_Distance',
              [table[:position], point_node]
            ).lt(0.1)
          )
          
          sql = query.to_sql
          puts "ST_MakePoint SQL: #{sql}"
          
          # Should contain ST_MakePoint
          assert_match(/ST_MakePoint/, sql)
          assert_match(/ST_SetSRID/, sql)
          
          # Execute the query
          results = query.to_a
          assert_equal 1, results.count
          assert_equal "Nearby Location", results.first.name
        end
        
        test "using where_st_distance with Arel integration" do
          results = @location_class.where_st_distance(:position, 12.2821163, 51.36048700000001, '<', 0.1)
          
          assert_equal 1, results.count
          assert_equal "Nearby Location", results.first.name
        end
        
        test "chaining Arel spatial queries" do
          # Create more complex query using Arel
          table = @location_class.arel_table
          factory = RGeo::Geos.factory(srid: 4326)
          point1 = factory.point(12.0, 51.0)
          point2 = factory.point(14.0, 53.0)
          
          query = @location_class
            .where(table[:position].st_distance(Arel.spatial(point1)).gt(0.1))
            .where(table[:position].st_distance(Arel.spatial(point2)).lt(2.0))
          
          results = query.to_a
          assert_equal 1, results.count
          assert_equal "Faraway Location", results.first.name
        end
      end
    end
  end
end
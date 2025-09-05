# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SpatialQueriesHelperTest < ActiveSupport::TestCase
        def setup
          # Create test table if it doesn't exist
          unless SpatialModel.connection.table_exists?(:properties)
            SpatialModel.connection.create_table :properties, force: true do |t|
              t.st_point :lonlat, geographic: false, srid: 4326
              t.string :name
              t.timestamps
            end
          end

          # Create test model
          @property_class = Class.new(ActiveRecord::Base) do
            self.table_name = "properties"
          end

          # Create test data
          @property_class.delete_all
          @nearby = @property_class.create!(
            name: "Nearby Property",
            lonlat: "SRID=4326;POINT(12.28 51.36)"
          )
          @faraway = @property_class.create!(
            name: "Faraway Property",
            lonlat: "SRID=4326;POINT(13.0 52.0)"
          )
        end

        def teardown
          if defined?(@property_class) && SpatialModel.connection.table_exists?(:properties)
            SpatialModel.connection.drop_table :properties
          end
        end

        test "where_st_distance finds nearby points" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000

          # Use geographic: true for meter-based calculations
          results = @property_class.where_st_distance(:lonlat, lon, lat, "<", meter_radius, geographic: true)

          assert_equal 1, results.count
          assert_equal "Nearby Property", results.first.name
        end

        test "where_st_dwithin finds points within distance" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000

          # Use geographic: true for meter-based calculations
          results = @property_class.where_st_dwithin(:lonlat, lon, lat, meter_radius, geographic: true)

          assert_equal 1, results.count
          assert_equal "Nearby Property", results.first.name
        end

        test "spatial scopes work correctly" do
          # First include the SpatialScopes module
          @property_class.include(ActiveRecord::ConnectionAdapters::PostGIS::SpatialScopes)

          lon = 12.2821163
          lat = 51.36048700000001

          # Test within_distance scope with geographic calculation
          results = @property_class.within_distance(:lonlat, lon, lat, 5000, geographic: true)
          assert_equal 1, results.count
          assert_equal "Nearby Property", results.first.name

          # Test beyond_distance scope with geographic calculation
          results = @property_class.beyond_distance(:lonlat, lon, lat, 50000, geographic: true)
          assert_equal 1, results.count
          assert_equal "Faraway Property", results.first.name

          # Test near scope with geographic calculation
          results = @property_class.near(:lonlat, lon, lat, 5000, geographic: true)
          assert_equal 1, results.count
          assert_equal "Nearby Property", results.first.name
        end

        test "generated SQL uses ST_MakePoint instead of string interpolation" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000

          query = @property_class.where_st_distance(:lonlat, lon, lat, "<", meter_radius)
          sql = query.to_sql

          # Should contain ST_MakePoint, not 'POINT(...)'
          assert_match(/ST_MakePoint/, sql)
          refute_match(/'POINT\(/, sql)
        end
      end
    end
  end
end

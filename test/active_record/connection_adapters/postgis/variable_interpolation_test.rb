# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class VariableInterpolationTest < ActiveSupport::TestCase
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
          @property = @property_class.create!(
            name: "Test Property",
            lonlat: "POINT(12.0 51.0)"
          )
        end
        
        def teardown
          # Rollback any failed transactions
          SpatialModel.connection.rollback_transaction if SpatialModel.connection.transaction_open?
          
          if defined?(@property_class) && SpatialModel.connection.table_exists?(:properties)
            SpatialModel.connection.drop_table :properties
          end
        end
        
        test "ST_Distance with variable interpolation in WHERE clause" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000
          
          # This is the problematic query from the issue
          query = @property_class.where("ST_Distance(lonlat, 'POINT(? ?)') < ?", lon, lat, meter_radius)
          
          # Check the SQL to see if placeholders are preserved
          sql = query.to_sql
          puts "Generated SQL: #{sql}"
          
          # Try to execute the query - this WILL FAIL due to interpolation issue
          assert_raises ActiveRecord::StatementInvalid do
            query.count
          end
        end
        
        test "ST_Distance with ST_MakePoint for comparison" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000
          
          # Alternative approach using ST_MakePoint with SRID
          query = @property_class.where("ST_Distance(lonlat, ST_SetSRID(ST_MakePoint(?, ?), 4326)) < ?", lon, lat, meter_radius)
          
          sql = query.to_sql
          puts "Generated SQL with ST_MakePoint: #{sql}"
          
          assert_nothing_raised do
            count = query.count
            puts "ST_MakePoint query executed successfully, found #{count} records"
          end
        end
        
        test "ST_Distance with ST_GeomFromText and concatenation" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000
          
          # Another approach using string concatenation
          point_wkt = "POINT(#{lon} #{lat})"
          query = @property_class.where("ST_Distance(lonlat, ST_GeomFromText(?, 4326)) < ?", point_wkt, meter_radius)
          
          sql = query.to_sql
          puts "Generated SQL with ST_GeomFromText: #{sql}"
          
          assert_nothing_raised do
            count = query.count
            puts "ST_GeomFromText query executed successfully, found #{count} records"
          end
        end
        
        test "verify placeholder behavior in logs" do
          lon = 12.2821163
          lat = 51.36048700000001
          meter_radius = 5000
          
          # Capture logs to see what's being sent to the database
          logs = capture_sql do
            begin
              @property_class.where("ST_Distance(lonlat, 'POINT(? ?)') < ?", lon, lat, meter_radius).count
            rescue ActiveRecord::StatementInvalid
              # Expected to fail
            end
          end
          
          puts "Captured SQL logs:"
          logs.each { |log| puts log }
          
          # Check that placeholders ARE being converted incorrectly (this is the bug)
          problematic_pattern = /POINT\(\$1 \$2\)/
          assert logs.any? { |log| log.match?(problematic_pattern) }, 
                 "Expected to find problematic placeholder pattern in SQL"
        end
        
        private
        
        def capture_sql
          logs = []
          subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, details|
            logs << details[:sql] if details[:sql]
          end
          
          yield
          
          logs
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end
      end
    end
  end
end
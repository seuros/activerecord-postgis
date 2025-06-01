# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class ConstraintTest < ActiveSupport::TestCase
        def teardown
          reset_spatial_store
          cleanup_test_tables
        end

        def test_spatial_index_creation
          # Test creating spatial indexes (GiST/SP-GiST)
          create_spatial_table

          connection = SpatialModel.lease_connection

          # Add GiST index
          connection.add_index :test_spatial, :location, using: :gist

          indexes = connection.indexes(:test_spatial)
          spatial_index = indexes.find { |idx| idx.columns == [ "location" ] }

          assert_not_nil spatial_index, "Should create spatial index"
          assert_equal "gist", spatial_index.using.to_s if spatial_index.respond_to?(:using)
        end

        def test_spatial_constraint_validation
          # Test that PostGIS constraints are properly handled
          create_spatial_table

          # This should work - valid geometry
          SpatialModel.create!(
            location: factory(srid: 4326).point(0, 0),
            name: "Valid Point"
          )

          # Test with different SRID (should raise constraint error)
          assert_raises(ActiveRecord::StatementInvalid) do
            SpatialModel.create!(
              location: factory(srid: 3857).point(0, 0),
              name: "Different SRID Point"
            )
          end
        end

        def test_check_constraint_for_geometry_type
          # Test type constraints in PostGIS
          connection = SpatialModel.lease_connection

          connection.create_table(:constrained_spatial, force: true) do |t|
            t.column "point_only", :st_point, srid: 4326
            t.column "polygon_only", :st_polygon, srid: 4326
            t.string "name"
          end

          constrained_model = Class.new(ActiveRecord::Base) do
            self.table_name = "constrained_spatial"
          end

          # Valid types should work
          point = factory(srid: 4326).point(1, 2)
          polygon = factory(srid: 4326).polygon(
            factory(srid: 4326).linear_ring([
              factory(srid: 4326).point(0, 0),
              factory(srid: 4326).point(0, 1),
              factory(srid: 4326).point(1, 1),
              factory(srid: 4326).point(1, 0),
              factory(srid: 4326).point(0, 0)
            ])
          )

          record = constrained_model.create!(
            point_only: point,
            polygon_only: polygon,
            name: "Valid Types"
          )

          assert_not_nil record.id
        end

        private

        def create_spatial_table
          SpatialModel.lease_connection.create_table(:test_spatial, force: true) do |t|
            t.column "location", :st_point, srid: 4326
            t.string "name"
          end

          # Update SpatialModel to use the new table temporarily
          SpatialModel.table_name = "test_spatial"
          SpatialModel.reset_column_information
        end

        def cleanup_test_tables
          connection = SpatialModel.lease_connection
          %w[test_spatial constrained_spatial].each do |table_name|
            if connection.table_exists?(table_name)
              connection.drop_table(table_name)
            end
          end

          # Reset SpatialModel table
          SpatialModel.table_name = "spatial_models"
        rescue => e
          Rails.logger&.debug("Cleanup error: #{e.message}")
        end
      end
    end
  end
end

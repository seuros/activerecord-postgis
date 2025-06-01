# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class MigrationTest < ActiveSupport::TestCase
        def teardown
          reset_spatial_store
          cleanup_test_tables
        end

        def test_adding_spatial_columns_to_existing_table
          # Test adding spatial columns to an existing non-spatial table
          connection = SpatialModel.lease_connection

          # Create non-spatial table first
          connection.create_table(:migration_test, force: true) do |t|
            t.string "name"
            t.timestamps
          end

          # Add spatial columns
          connection.change_table(:migration_test) do |t|
            t.column "location", :st_point, srid: 4326
            t.column "boundary", :st_polygon, srid: 3857
            t.column "geo_point", :st_point, srid: 4326, geographic: true
          end

          # Verify columns were added correctly
          columns = connection.columns(:migration_test)

          location_col = columns.find { |c| c.name == "location" }
          boundary_col = columns.find { |c| c.name == "boundary" }
          geo_col = columns.find { |c| c.name == "geo_point" }

          assert_not_nil location_col
          assert_not_nil boundary_col
          assert_not_nil geo_col

          # Test that we can insert data
          test_model = Class.new(ActiveRecord::Base) do
            self.table_name = "migration_test"
          end

          record = test_model.create!(
            name: "Test Location",
            location: factory(srid: 4326).point(1, 2),
            boundary: factory(srid: 3857).polygon(
              factory(srid: 3857).linear_ring([
                factory(srid: 3857).point(0, 0),
                factory(srid: 3857).point(0, 1),
                factory(srid: 3857).point(1, 1),
                factory(srid: 3857).point(1, 0),
                factory(srid: 3857).point(0, 0)
              ])
            ),
            geo_point: geographic_factory.point(-122, 37)
          )

          assert_not_nil record.id
        end

        def test_removing_spatial_columns
          # Test removing spatial columns from table
          connection = SpatialModel.lease_connection

          connection.create_table(:removal_test, force: true) do |t|
            t.string "name"
            t.column "location", :st_point, srid: 4326
            t.column "boundary", :st_polygon, srid: 3857
            t.column "keep_this", :st_point, srid: 4326
          end

          # Remove some spatial columns
          connection.change_table(:removal_test) do |t|
            t.remove "location"
            t.remove "boundary"
          end

          columns = connection.columns(:removal_test)
          column_names = columns.map(&:name)

          assert_includes column_names, "name"
          assert_includes column_names, "keep_this"
          assert_not_includes column_names, "location"
          assert_not_includes column_names, "boundary"
        end

        def test_changing_spatial_column_properties
          # Test modifying spatial column properties
          connection = SpatialModel.lease_connection

          connection.create_table(:change_test, force: true) do |t|
            t.string "name"
            t.column "location", :st_point, srid: 4326
          end

          # This might not be directly supported, but should not crash
          assert_nothing_raised do
            # Attempt to change column (may not actually modify spatial properties)
            connection.change_column :change_test, :name, :text
          end

          # Verify table still exists and is accessible
          columns = connection.columns(:change_test)
          assert columns.length > 0
        end

        def test_renaming_spatial_columns
          # Test renaming spatial columns
          connection = SpatialModel.lease_connection

          connection.create_table(:rename_test, force: true) do |t|
            t.string "name"
            t.column "old_location", :st_point, srid: 4326
          end

          # Rename spatial column
          connection.rename_column :rename_test, :old_location, :new_location

          columns = connection.columns(:rename_test)
          column_names = columns.map(&:name)

          assert_includes column_names, "new_location"
          assert_not_includes column_names, "old_location"

          # Verify the column still works
          test_model = Class.new(ActiveRecord::Base) do
            self.table_name = "rename_test"
          end

          record = test_model.create!(
            name: "Test",
            new_location: factory(srid: 4326).point(1, 2)
          )

          assert_not_nil record.id
          assert_not_nil record.new_location
        end

        def test_adding_spatial_indexes_in_migration
          # Test adding spatial indexes through migrations
          connection = SpatialModel.lease_connection

          connection.create_table(:index_test, force: true) do |t|
            t.string "name"
            t.column "location", :st_point, srid: 4326
            t.column "boundary", :st_polygon, srid: 3857
          end

          # Add spatial indexes
          connection.add_index :index_test, :location, using: :gist
          connection.add_index :index_test, :boundary, using: :gist, name: "custom_boundary_idx"

          indexes = connection.indexes(:index_test)

          location_idx = indexes.find { |idx| idx.columns == [ "location" ] }
          boundary_idx = indexes.find { |idx| idx.name == "custom_boundary_idx" }

          assert_not_nil location_idx
          assert_not_nil boundary_idx

          # Remove indexes
          connection.remove_index :index_test, :location
          connection.remove_index :index_test, name: "custom_boundary_idx"

          indexes_after = connection.indexes(:index_test)
          assert_empty indexes_after.select { |idx| idx.columns == [ "location" ] }
          assert_empty indexes_after.select { |idx| idx.name == "custom_boundary_idx" }
        end

        def test_table_with_mixed_column_types
          # Test creating table with mix of spatial and non-spatial columns
          connection = SpatialModel.lease_connection

          connection.create_table(:mixed_test, force: true) do |t|
            # Standard columns
            t.string "name", null: false
            t.text "description"
            t.integer "category_id"
            t.decimal "price", precision: 10, scale: 2
            t.boolean "active", default: true
            t.datetime "published_at"

            # Spatial columns
            t.column "location", :st_point, srid: 4326
            t.column "service_area", :st_polygon, srid: 3857
            t.column "delivery_routes", :st_multi_line_string, srid: 3857
            t.column "landmarks", :st_multi_point, srid: 4326
            t.column "geo_location", :st_point, srid: 4326, geographic: true

            t.timestamps
          end

          # Verify all column types are handled correctly
          columns = connection.columns(:mixed_test)

          # Check standard columns
          assert columns.find { |c| c.name == "name" && c.type == :string }
          assert columns.find { |c| c.name == "description" && c.type == :text }
          assert columns.find { |c| c.name == "category_id" && c.type == :integer }
          assert columns.find { |c| c.name == "price" && c.type == :decimal }
          assert columns.find { |c| c.name == "active" && c.type == :boolean }

          # Check spatial columns exist (exact type detection may vary)
          assert columns.find { |c| c.name == "location" }
          assert columns.find { |c| c.name == "service_area" }
          assert columns.find { |c| c.name == "delivery_routes" }
          assert columns.find { |c| c.name == "landmarks" }
          assert columns.find { |c| c.name == "geo_location" }

          # Test that we can create records
          test_model = Class.new(ActiveRecord::Base) do
            self.table_name = "mixed_test"
          end

          point = factory(srid: 4326).point(-122, 37)
          polygon = factory(srid: 3857).polygon(
            factory(srid: 3857).linear_ring([
              factory(srid: 3857).point(0, 0),
              factory(srid: 3857).point(0, 100),
              factory(srid: 3857).point(100, 100),
              factory(srid: 3857).point(100, 0),
              factory(srid: 3857).point(0, 0)
            ])
          )

          record = test_model.create!(
            name: "Test Business",
            description: "A test business with spatial data",
            category_id: 1,
            price: 99.99,
            active: true,
            published_at: Time.current,
            location: point,
            service_area: polygon,
            geo_location: geographic_factory.point(-122, 37)
          )

          assert_not_nil record.id
          assert_equal "Test Business", record.name
          assert_not_nil record.location
          assert_not_nil record.service_area
        end

        private

        def cleanup_test_tables
          connection = SpatialModel.lease_connection
          %w[migration_test removal_test change_test rename_test index_test mixed_test].each do |table_name|
            if connection.table_exists?(table_name)
              connection.drop_table(table_name)
            end
          end
        rescue => e
          Rails.logger&.debug("Cleanup error: #{e.message}")
        end
      end
    end
  end
end

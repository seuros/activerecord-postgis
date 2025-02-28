# frozen_string_literal: true

class CreateRoutes < ActiveRecord::Migration[8.0]
  def up
    # Test Z and M dimensions
    create_table :routes do |t|
      t.string :name
      t.float :distance
      t.timestamps
    end

    execute <<-SQL
      -- 3D geometries (with Z coordinate for elevation)
      ALTER TABLE routes
        ADD COLUMN path_3d geometry(LineStringZ, 4326),
        ADD COLUMN waypoints_3d geometry(MultiPointZ, 4326);
      #{'  '}
      -- Measured geometries (with M coordinate for linear referencing)
      ALTER TABLE routes
        ADD COLUMN path_measured geometry(LineStringM, 4326);
      #{'  '}
      -- 4D geometries (both Z and M)
      ALTER TABLE routes
        ADD COLUMN path_4d geometry(LineStringZM, 4326);
    SQL
  end

  def down
    drop_table :routes
  end
end

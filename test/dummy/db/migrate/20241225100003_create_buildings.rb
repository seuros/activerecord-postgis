# frozen_string_literal: true

class CreateBuildings < ActiveRecord::Migration[8.0]
  def up
    # Test geometry types with specific SRIDs
    create_table :buildings do |t|
      t.string :name
      t.integer :floors
      t.timestamps
    end

    # Add geometry columns with different SRIDs
    execute <<-SQL
      -- WGS 84 / UTM zone 33N (SRID: 32633)
      ALTER TABLE buildings#{' '}
        ADD COLUMN footprint geometry(Polygon, 32633),
        ADD COLUMN entrance geometry(Point, 32633);
      #{'  '}
      -- Web Mercator (SRID: 3857)#{' '}
      ALTER TABLE buildings
        ADD COLUMN location_mercator geometry(Point, 3857);
      #{'  '}
      -- State Plane California Zone 3 (SRID: 2227)
      ALTER TABLE buildings
        ADD COLUMN location_ca geometry(Point, 2227);
    SQL
  end

  def down
    drop_table :buildings
  end
end

# frozen_string_literal: true

class CreateMixedSpatialTable < ActiveRecord::Migration[8.0]
  def up
    # Test mixing geometry and geography in same table
    create_table :mixed_spatial do |t|
      t.string :name
      t.timestamps
    end

    execute <<-SQL
      -- Add generic geometry column
      ALTER TABLE mixed_spatial
        ADD COLUMN shape geometry;
      #{'  '}
      -- Add specific geometry subtypes
      ALTER TABLE mixed_spatial
        ADD COLUMN geom_point geometry(Point, 4326),
        ADD COLUMN geom_line geometry(LineString, 3857),
        ADD COLUMN geom_poly geometry(Polygon, 2154);  -- French Lambert 93
      #{'  '}
      -- Add geography columns#{'  '}
      ALTER TABLE mixed_spatial
        ADD COLUMN geog_point geography(Point, 4326),
        ADD COLUMN geog_line geography(LineString, 4326),
        ADD COLUMN geog_poly geography(Polygon, 4326);
      #{'  '}
      -- Add comments
      COMMENT ON COLUMN mixed_spatial.shape IS 'Generic geometry column';
      COMMENT ON COLUMN mixed_spatial.geom_point IS 'WGS84 geometry point';
      COMMENT ON COLUMN mixed_spatial.geog_point IS 'WGS84 geography point';
    SQL
  end

  def down
    drop_table :mixed_spatial
  end
end

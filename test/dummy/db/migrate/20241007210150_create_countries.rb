# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[7.2]
  def up
    create_table :countries do |t|
      t.string :name, comment: "Name of the Country"
      t.timestamps
    end

    # Add all spatial columns in a single transaction
    execute <<-SQL.strip_heredoc
      ALTER TABLE countries
        ADD COLUMN point_geom geography(Point, 4326),
        ADD COLUMN line_geom geography(LineString, 4326),
        ADD COLUMN polygon_geom geography(Polygon, 4326),
        ADD COLUMN multipoint_geom geography(MultiPoint, 4326),
        ADD COLUMN multipolygon_geom geography(MultiPolygon, 4326),
        ADD COLUMN geometry_collection geography(GeometryCollection, 4326),
        ADD COLUMN multilinestring_geom geography(MultiLineString, 4326);

      COMMENT ON COLUMN countries.point_geom IS '2D point geometry';
      COMMENT ON COLUMN countries.line_geom IS 'LineString geometry';
      COMMENT ON COLUMN countries.polygon_geom IS 'Polygon geometry';
      COMMENT ON COLUMN countries.multipoint_geom IS 'MultiPoint geometry';
      COMMENT ON COLUMN countries.multipolygon_geom IS 'MultiPolygon geometry';
      COMMENT ON COLUMN countries.geometry_collection IS 'GeometryCollection type';
      COMMENT ON COLUMN countries.multilinestring_geom IS 'MultiLineString geometry';
    SQL
  end

  def down
    drop_table :countries
  end
end
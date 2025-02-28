# frozen_string_literal: true

class TestNativePgTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :test_native_pg_types do |t|
      t.string :name

      # PostgreSQL native geometric types (not PostGIS)
      t.point :pg_point        # PostgreSQL native point
      t.polygon :pg_polygon    # PostgreSQL native polygon

      # PostGIS spatial types
      t.st_point :gis_point    # PostGIS geometry(Point)
      t.st_polygon :gis_polygon # PostGIS geometry(Polygon)

      t.timestamps
    end
  end
end

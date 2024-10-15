# frozen_string_literal: true

class CreateCountries < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :name, comment: "Name of the Country"

      # PostGIS spatial columns using custom type methods with comments
      # t.st_geography :latlong, comment: "Geographic point with longitude/latitude"
      # t.st_geometry :geometry, comment: "Generic geometry column"
      t.st_point :point_geom, comment: "2D point geometry", geographic: true
      t.st_line_string :line_geom, comment: "LineString geometry", geographic: true
      t.st_polygon :polygon_geom, comment: "Polygon geometry", geographic: true
      t.st_multi_point :multipoint_geom, comment: "MultiPoint geometry", geographic: true
      t.st_multi_polygon :multipolygon_geom, comment: "MultiPolygon geometry", geographic: true
      t.st_geometry_collection :geometry_collection, comment: "GeometryCollection type", geographic: true
      t.st_multi_line_string :multilinestring_geom, comment: "MultiLineString geometry", geographic: true

      t.timestamps
    end
  end
end

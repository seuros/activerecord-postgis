# frozen_string_literal: true

class TestSpatialColumnMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :test_spatial_methods do |t|
      t.string :name

      # Test various column method syntaxes
      t.st_point :location
      t.st_line_string :path
      t.st_polygon :area
      t.st_multi_point :points
      t.st_multi_line_string :paths
      t.st_multi_polygon :areas
      t.st_geometry_collection :features
      t.st_geometry :shape
      t.st_geography :region

      t.timestamps
    end
  end
end

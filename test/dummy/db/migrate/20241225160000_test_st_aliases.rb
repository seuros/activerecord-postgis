# frozen_string_literal: true

class TestStAliases < ActiveRecord::Migration[8.0]
  def change
    create_table :test_st_aliases do |t|
      t.string :name

      # Test st_* aliases for backward compatibility
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

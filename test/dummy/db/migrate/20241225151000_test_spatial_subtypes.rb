# frozen_string_literal: true

class TestSpatialSubtypes < ActiveRecord::Migration[8.0]
  def change
    create_table :test_spatial_subtypes do |t|
      t.string :name

      # Test specific geometry subtypes
      t.st_point :location
      t.st_line_string :path
      t.st_polygon :area

      t.timestamps
    end
  end
end

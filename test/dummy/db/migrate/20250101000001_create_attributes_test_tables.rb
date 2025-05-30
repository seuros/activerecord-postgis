# frozen_string_literal: true

class CreateAttributesTestTables < ActiveRecord::Migration[8.0]
  def change
    create_table :foos do |t|
      t.timestamps
    end

    create_table :spatial_foos do |t|
      t.references :foo, null: false, foreign_key: true
      t.st_point :geo_point, geographic: true, srid: 4326
      t.st_point :cart_point, srid: 3509
      t.timestamps
    end

    create_table :invalid_attributes do |t|
      t.timestamps
    end
  end
end

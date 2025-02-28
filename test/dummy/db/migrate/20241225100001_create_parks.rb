# frozen_string_literal: true

class CreateParks < ActiveRecord::Migration[8.0]
  def up
    # Test multi* geometry types
    create_table :parks do |t|
      t.string :name
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE parks
        ADD COLUMN entrances geometry(MultiPoint),
        ADD COLUMN trails geometry(MultiLineString),
        ADD COLUMN zones geometry(MultiPolygon),
        ADD COLUMN features geometry(GeometryCollection);
    SQL
  end

  def down
    drop_table :parks
  end
end

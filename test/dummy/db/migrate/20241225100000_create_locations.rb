# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def up
    # Test basic geometry types with default SRID (0)
    create_table :locations do |t|
      t.string :name
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE locations
        ADD COLUMN position geometry(Point),
        ADD COLUMN route geometry(LineString),
        ADD COLUMN boundary geometry(Polygon);
    SQL
  end

  def down
    drop_table :locations
  end
end

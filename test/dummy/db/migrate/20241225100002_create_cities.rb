# frozen_string_literal: true

class CreateCities < ActiveRecord::Migration[8.0]
  def up
    # Test geography types (always SRID 4326)
    create_table :cities do |t|
      t.string :name
      t.timestamps
    end

    # Add geography columns using SQL for explicit type specification
    execute <<-SQL
      ALTER TABLE cities#{' '}
        ADD COLUMN center geography(Point, 4326),
        ADD COLUMN boundaries geography(Polygon, 4326),
        ADD COLUMN districts geography(MultiPolygon, 4326);
    SQL
  end

  def down
    drop_table :cities
  end
end

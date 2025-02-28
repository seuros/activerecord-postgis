# frozen_string_literal: true

# Migration to establish land masses unfortunately burdened with political entities
class CreateLandMassesWithPoliticians < ActiveRecord::Migration[8.0]
  def change
    create_table :land_masses_with_politicians, comment: "Geographic territories burdened with political entities and their complications 🌍🎭" do |t|
      t.string :name, comment: "Official designation of the political experiment"
      t.st_point :location, comment: "Precise PostGIS coordinates (more accurate than their political promises)"
      t.timestamps null: false, comment: "When this political arrangement was last stable"
    end

    # Add satirical explanation
    execute <<-SQL
      COMMENT ON TABLE land_masses_with_politicians IS#{' '}
        'Geographic territories inhabited by political entities and their associated complications.
         PostGIS spatial precision tracks land boundaries with mathematical accuracy,
         while political boundaries remain perpetually questionable.
         🌍🎭 Warning: May contain traces of democracy, corruption, and campaign promises.
         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord - Political Geography Edition';
    SQL
  end
end

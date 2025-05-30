# frozen_string_literal: true

# Migration for quantum photons in the SQLite dimension
# These particles exist in a classical database without spatial awareness
class CreateQuantumPhotons < ActiveRecord::Migration[8.0]
  def change
    create_table :quantum_photons, id: :string, primary_key: :id do |t|
      t.string :wavelength, null: false, comment: "Light wavelength in nanometers"
      t.float :energy_level, comment: "Photon energy in electron volts"
      t.boolean :polarized, default: false, comment: "Is the photon polarized?"
      t.string :source_star, comment: "Which star emitted this photon"

      t.timestamps null: false, comment: "Classical time tracking"
    end

    add_index :quantum_photons, :wavelength
    add_index :quantum_photons, :energy_level
  end
end

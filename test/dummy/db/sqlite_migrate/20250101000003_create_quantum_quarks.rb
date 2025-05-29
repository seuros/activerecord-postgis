# frozen_string_literal: true

# Migration for quantum quarks in the SQLite dimension  
# The most fundamental particles, stored in classical relational format
class CreateQuantumQuarks < ActiveRecord::Migration[8.0]
  def change
    create_table :quantum_quarks, id: :string, primary_key: :id do |t|
      t.string :flavor, null: false, comment: "Quark flavor: up, down, charm, strange, top, bottom"
      t.string :color_charge, null: false, comment: "Color charge: red, green, blue"
      t.float :mass, comment: "Quark mass in MeV/c²"
      t.string :proton_id, comment: "Which proton contains this quark"
      t.string :neutron_id, comment: "Which neutron contains this quark"
      t.boolean :confined, default: true, comment: "Quarks are always confined in hadrons"
      
      t.timestamps null: false, comment: "Classical time tracking"
    end

    add_index :quantum_quarks, :flavor
    add_index :quantum_quarks, :color_charge
    add_index :quantum_quarks, :proton_id
    add_index :quantum_quarks, :neutron_id
  end
end
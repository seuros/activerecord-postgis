# frozen_string_literal: true

# Migration for quantum electrons in the SQLite dimension
# These particles follow classical database rules without spatial extensions
class CreateQuantumElectrons < ActiveRecord::Migration[8.0]
  def change
    create_table :quantum_electrons, id: :string, primary_key: :id do |t|
      t.string :spin_state, null: false, comment: "Electron spin: up or down"
      t.integer :energy_shell, comment: "Which electron shell (1, 2, 3, etc.)"
      t.string :atom_id, comment: "Which atom contains this electron"
      t.float :charge, default: -1.0, comment: "Electric charge (always negative)"
      t.boolean :paired, default: false, comment: "Is electron paired with another?"
      
      t.timestamps null: false, comment: "Classical time tracking"
    end

    add_index :quantum_electrons, :atom_id
    add_index :quantum_electrons, :energy_shell
    add_index :quantum_electrons, [:spin_state, :paired]
  end
end
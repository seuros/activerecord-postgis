# frozen_string_literal: true

# Migration to create quantum observers in the parallel PostgreSQL dimension
class CreateQuantumObservers < ActiveRecord::Migration[8.0]
  def up
    create_table :quantum_observers, comment: "Entities existing in the parallel PostgreSQL dimension where quantum mechanics don't apply" do |t|
      t.string :name, null: false, comment: "Quantum state identifier - collapses upon observation"
      t.string :email, null: false, comment: "Quantum entangled communication channel across dimensions"
      t.point :coordinates, comment: "Classical Newtonian coordinates (no quantum superposition here!)"

      t.timestamps null: false, comment: "Timestamp of last quantum measurement collapse"
    end

    add_index :quantum_observers, :email, unique: true

    # Add table comment explaining the quantum nature
    execute <<-SQL
      COMMENT ON TABLE quantum_observers IS#{' '}
        'Parallel dimension entities using classical PostgreSQL physics only.#{' '}
         No PostGIS quantum spatial types allowed in this reality!
         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord';
    SQL
  end
end

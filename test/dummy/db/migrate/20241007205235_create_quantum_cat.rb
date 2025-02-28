# frozen_string_literal: true

# Migration to create quantum cats existing in superposition until observed
class CreateQuantumCat < ActiveRecord::Migration[8.0]
  def up
    enable_extension "uuid-ossp"

    create_table :quantum_cats, id: :uuid, comment: "Schrödinger's cats existing in quantum superposition 🐱📦" do |t|
      t.string :name, comment: "Cat identifier - observing this field collapses the quantum state"

      t.timestamps null: false, comment: "When the cat's state was last observed"
    end

    # Add quantum physics explanation
    execute <<-SQL
      COMMENT ON TABLE quantum_cats IS#{' '}
        'Quantum felines existing in superposition states until observed.
         Each cat exists simultaneously in all possible states within the PostGIS quantum spatial dimension.
         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord - PostGIS Edition';
    SQL
  end
end

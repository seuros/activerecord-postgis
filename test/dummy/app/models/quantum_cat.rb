# frozen_string_literal: true

# == Schema Information
#
# Table name: quantum_cats
#
#  id         :uuid             not null, primary key
#  name       :string           comment: "Cat identifier - observing this field collapses the quantum state"
#  created_at :datetime         not null, comment: "When the cat's state was last observed"
#  updated_at :datetime         not null, comment: "When the cat's state was last observed"
#
# Schrödinger's quantum cat existing in superposition within the PostGIS spatial dimension
# Until observed, each cat simultaneously exists in all possible quantum states! 🐱📦⚛️
class QuantumCat < ApplicationRecord
  # Quantum cats use the primary PostGIS database (quantum spatial dimension)
  # They can exist in multiple spatial locations simultaneously until measured
end

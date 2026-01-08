# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "quantum_cats"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "uuid", pk = true, null = false },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "name", type = "string" },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# table_comment = "Quantum felines existing in superposition states until observed.
#          Each cat exists simultaneously in all possible states within the PostGIS quantum spatial dimension.
#          🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord - PostGIS Edition"
#
# notes = ["name:NOT_NULL", "name:LIMIT"]
# <rails-lens:schema:end>
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

# frozen_string_literal: true

# Base class for quantum particles existing in the SQLite dimension
# These particles exist in classical relational space without spatial awareness
class QuantumParticle < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :sqlite, reading: :sqlite }
  
  # Quantum particles in SQLite follow classical physics laws
  # No spatial extensions available - they exist in pure relational space
end
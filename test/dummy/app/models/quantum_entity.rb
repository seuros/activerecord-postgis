# frozen_string_literal: true

# Base class for quantum entities existing in parallel universe
class QuantumEntity < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :secondary, reading: :secondary }
end

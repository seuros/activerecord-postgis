# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "quantum_observers"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "coordinates", type = "point" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "email", type = "string", null = false },
#   { name = "name", type = "string", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_quantum_observers_on_email", columns = ["email"], unique = true }
# ]
#
# table_comment = "Entities existing in the parallel PostgreSQL dimension where quantum mechanics don't apply"
#
# notes = ["coordinates:NOT_NULL", "email:LIMIT", "name:LIMIT"]
# <rails-lens:schema:end>
# A quantum observer existing in the parallel PostgreSQL dimension
# Uses plain coordinates (not spatial) - exists in Newtonian reality
class QuantumObserver < QuantumEntity
  # This entity exists in the secondary database (plain PostgreSQL without PostGIS)
  # Their coordinates collapse to classical point values when observed
end

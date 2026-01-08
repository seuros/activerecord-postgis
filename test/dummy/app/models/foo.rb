# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "foos"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# notes = ["spatial_foo:INVERSE_OF"]
# <rails-lens:schema:end>
class Foo < ApplicationRecord
  has_one :spatial_foo
  attribute :bar, :string, array: true
  attribute :baz, :string, range: true
end

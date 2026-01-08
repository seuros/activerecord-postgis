# frozen_string_literal: true

# <rails-lens:schema:begin>
# table = "spatial_foos"
# database_dialect = "PostgreSQL"
#
# columns = [
#   { name = "id", type = "integer", pk = true, null = false },
#   { name = "cart_point", type = "st_point" },
#   { name = "created_at", type = "datetime", null = false },
#   { name = "foo_id", type = "integer", null = false },
#   { name = "geo_point", type = "st_point" },
#   { name = "updated_at", type = "datetime", null = false }
# ]
#
# indexes = [
#   { name = "index_spatial_foos_on_foo_id", columns = ["foo_id"] }
# ]
#
# foreign_keys = [
#   { column = "foo_id", references_table = "foos", references_column = "id", name = "fk_rails_6d8e1b79ee" }
# ]
#
# notes = ["foo:INVERSE_OF", "cart_point:NOT_NULL", "geo_point:NOT_NULL"]
# <rails-lens:schema:end>
class SpatialFoo < ApplicationRecord
  belongs_to :foo
  attribute :point, :st_point, srid: 3857
  attribute :pointz, :st_point, has_z: true, srid: 3509
  attribute :pointm, :st_point, has_m: true, srid: 3509
  attribute :polygon, :st_polygon, srid: 3857
  attribute :path, :line_string, srid: 3857
  attribute :geo_path, :line_string, geographic: true, srid: 4326
end

# frozen_string_literal: true

class SpatialFoo < ApplicationRecord
  belongs_to :foo
  attribute :point, :st_point, srid: 3857
  attribute :pointz, :st_point, has_z: true, srid: 3509
  attribute :pointm, :st_point, has_m: true, srid: 3509
  attribute :polygon, :st_polygon, srid: 3857
  attribute :path, :line_string, srid: 3857
  attribute :geo_path, :line_string, geographic: true, srid: 4326
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
#  id                                             :bigint           not null, primary key
#  geometry_collection(GeometryCollection type)   :geography(Geomet
#  line_geom(LineString geometry)                 :geography(LineSt
#  multilinestring_geom(MultiLineString geometry) :geography(MultiL
#  multipoint_geom(MultiPoint geometry)           :geography(MultiP
#  multipolygon_geom(MultiPolygon geometry)       :geography(MultiP
#  name(Name of the Country)                      :string
#  point_geom(2D point geometry)                  :geography(Point,
#  polygon_geom(Polygon geometry)                 :geography(Polygo
#  created_at                                     :datetime         not null
#  updated_at                                     :datetime         not null
#
class Country < ApplicationRecord
end

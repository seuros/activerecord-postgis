# frozen_string_literal: true

require "test_helper"

class TypeShareabilityTest < ActiveSupport::TestCase
  SPATIAL_TYPES = [
    ActiveRecord::ConnectionAdapters::PostGIS::Type::Geometry,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::Geography,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::Point,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::LineString,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::Polygon,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::MultiPoint,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::MultiLineString,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::MultiPolygon,
    ActiveRecord::ConnectionAdapters::PostGIS::Type::GeometryCollection
  ].freeze

  # Rails freezes cast types for Ractor sharing; a retained RGeo factory
  # (mutexes, procs) would make the schema context unshareable.
  def test_spatial_type_instances_are_ractor_shareable
    skip "Ractor.make_shareable not available" unless defined?(Ractor)

    SPATIAL_TYPES.each do |klass|
      type = klass.new(srid: 4326, has_z: false, has_m: false)
      assert_nothing_raised do
        Ractor.make_shareable(type)
      end
    end
  end

  def test_cast_still_works_after_type_is_frozen
    skip "Ractor.make_shareable not available" unless defined?(Ractor)

    type = ActiveRecord::ConnectionAdapters::PostGIS::Type::Point.new(srid: 4326)
    Ractor.make_shareable(type)

    point = type.cast("SRID=4326;POINT(1.0 2.0)")
    assert_equal 1.0, point.x
    assert_equal 2.0, point.y
  end
end

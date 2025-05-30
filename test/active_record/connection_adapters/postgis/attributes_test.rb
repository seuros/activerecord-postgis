# frozen_string_literal: true

require "test_helper"

class AttributesTest < ActiveSupport::TestCase
  def test_postgresql_attributes_registered
    assert Foo.attribute_names.include?("bar")
    assert Foo.attribute_names.include?("baz")

    data = Foo.new
    data.bar = %w[a b c]
    data.baz = "1".."3"

    assert_equal data.bar, %w[a b c]
    assert_equal data.baz, "1".."3"
  end

  def test_invalid_attribute
    assert_raises(ArgumentError) do
      InvalidAttribute.attribute(:attr, :invalid_attr)
      InvalidAttribute.new
    end
  end

  def test_spatial_attributes
    data = SpatialFoo.new
    data.point = "POINT(0 0)"
    data.pointz = "POINT(0 0 1)"
    data.pointm = "POINT(0 0 2)"
    data.polygon = "POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))"
    data.path = "LINESTRING(0 0, 0 1, 1 1, 1 0, 0 0)"
    data.geo_path = "LINESTRING(-75.165222 39.952583,-73.561668 45.508888)"

    assert_equal 3857, data.point.srid
    assert_equal 0, data.point.x
    assert_equal 0, data.point.y

    assert_equal 3509, data.pointz.srid
    assert_equal 1, data.pointz.z

    assert_equal 3509, data.pointm.srid
    assert_equal 2, data.pointm.m

    assert_equal 3857, data.polygon.srid
    assert_equal 3857, data.path.srid

    # compare points instead of WKT representation because GEOS
    # handles rings and linestrings differently when generating WKT.
    assert_equal data.path.points, data.polygon.exterior_ring.points

    assert_equal 4326, data.geo_path.srid
    assert_equal RGeo::Geographic::Factory, data.geo_path.factory.class
  end

  def test_joined_spatial_attribute
    # TODO: The attributes that will be joined have to be defined on the
    # model we make the query with. Ideally, it would "just work" but
    # at least this workaround makes joining functional.
    Foo.attribute :geo_point, :st_point, srid: 4326, geographic: true
    Foo.attribute :cart_point, :st_point, srid: 3509

    foo = Foo.create
    SpatialFoo.create(foo_id: foo.id, geo_point: "POINT(10 10)", cart_point: "POINT(2 2)")

    # query foo and join child spatial foo on it
    foo = Foo.joins(:spatial_foo).select("foos.id, spatial_foos.geo_point, spatial_foos.cart_point").first

    assert_equal 4326, foo.geo_point.srid
    assert_equal 3509, foo.cart_point.srid

    # Compare coordinates instead of exact object equality due to factory differences
    assert_equal foo.geo_point.x, SpatialFoo.first.geo_point.x
    assert_equal foo.geo_point.y, SpatialFoo.first.geo_point.y
    assert_equal foo.cart_point.x, SpatialFoo.first.cart_point.x
    assert_equal foo.cart_point.y, SpatialFoo.first.cart_point.y
  end
end

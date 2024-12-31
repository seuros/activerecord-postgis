# frozen_string_literal: true

require "test_helper"

class SchemaDumperTest < ActiveSupport::TestCase
  test "only postgres is affected by schema dump ignore tables" do
    # List of tables to be ignored per your module
    ignored_tables = %w[
      geography_columns
      geometry_columns
      layer
      raster_columns
      raster_overviews
      spatial_ref_sys
      topology
    ]

    assert_equal(ignored_tables.to_set,
                 ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_tables.to_set, "PostgreSQL ignore tables do not match expected tables")
  end

  test "dump postgis types" do
    connection = ActiveRecord::Base.connection
    stream = StringIO.new
    dumper = ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.create(connection, {})
    connection.enable_extension("postgis")

    connection.execute(<<-SQL)
      CREATE TABLE locations (
        id serial PRIMARY KEY,
        point geometry(Point, 4326),
        line_string geometry(LineString, 4326),
        polygon geometry(Polygon, 4326)
      )
    SQL

    dumper.send(:dump, stream)
    output = stream.string
    puts output
    assert_includes output, 't.column "point", "geometry(Point,4326)"'
    # assert_includes output, 't.column "line_string", "geometry(LineString,4326)"'
    # assert_includes output, 't.column "polygon", "geometry(Polygon,4326)"'
  end
end

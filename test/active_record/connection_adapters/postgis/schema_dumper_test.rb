# frozen_string_literal: true

require "test_helper"

class SchemaDumperTest < ActiveSupport::TestCase
  setup do
    # Ensure PostGIS extension is enabled before running tests
    ActiveRecord::Base.connection.enable_extension("postgis") unless ActiveRecord::Base.connection.extension_enabled?("postgis")
    # Ensure PostGIS support is initialized
    ActiveRecord::ConnectionAdapters::PostGIS.initialize!
  end

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

    # Drop table if it exists before creating
    connection.drop_table :test_schema_dump_locations, if_exists: true

    connection.execute(<<-SQL)
      CREATE TABLE test_schema_dump_locations (
        id serial PRIMARY KEY,
        point geometry(Point, 4326),
        line_string geometry(LineString, 4326),
        polygon geometry(Polygon, 4326)
      )
    SQL

    begin
      dumper.send(:dump, stream)
      output = stream.string
      assert_includes output, 't.st_point "point", srid: 4326'
      assert_includes output, 't.st_line_string "line_string", srid: 4326'
      assert_includes output, 't.st_polygon "polygon", srid: 4326'
    ensure
      # Always clean up the table
      connection.drop_table :test_schema_dump_locations, if_exists: true
    end
  end
end

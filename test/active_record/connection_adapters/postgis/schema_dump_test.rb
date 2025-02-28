# frozen_string_literal: true

require "test_helper"

class SchemaDumpTest < ActiveSupport::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @connection.create_table :spatial_test, force: true do |t|
      t.string :name
      t.st_point :location
      t.st_line_string :path
      t.st_polygon :area
      t.st_multi_point :points
      t.st_multi_line_string :paths
      t.st_multi_polygon :areas
      t.st_geometry_collection :features
      t.st_geometry :shape
      t.st_geography :region
    end
  end

  def teardown
    @connection.drop_table :spatial_test, if_exists: true
  end

  test "schema dump includes all spatial column types" do
    schema = dump_table_schema("spatial_test")

    assert_match(/t\.st_point\s+"location"/, schema)
    assert_match(/t\.st_line_string\s+"path"/, schema)
    assert_match(/t\.st_polygon\s+"area"/, schema)
    assert_match(/t\.st_multi_point\s+"points"/, schema)
    assert_match(/t\.st_multi_line_string\s+"paths"/, schema)
    assert_match(/t\.st_multi_polygon\s+"areas"/, schema)
    assert_match(/t\.st_geometry_collection\s+"features"/, schema)
    assert_match(/t\.st_geometry\s+"shape"/, schema)
    assert_match(/t\.st_geography\s+"region"/, schema)
  end

  test "PostGIS system tables are ignored in schema dump" do
    schema = dump_schema

    # These PostGIS tables should not appear in the schema
    assert_no_match(/create_table\s+"spatial_ref_sys"/, schema)
    assert_no_match(/create_table\s+"geometry_columns"/, schema)
    assert_no_match(/create_table\s+"geography_columns"/, schema)
    assert_no_match(/create_table\s+"raster_columns"/, schema)
    assert_no_match(/create_table\s+"raster_overviews"/, schema)
  end

  test "schema dump includes PostGIS extension" do
    schema = dump_schema
    assert_match(/enable_extension\s+"postgis"/, schema)
  end

  private

  def dump_table_schema(table_name)
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(@connection.pool, stream)
    stream.string.lines.select { |line| line.include?(table_name) || line.match?(/^\s*t\./) }.join
  end

  def dump_schema
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(@connection.pool, stream)
    stream.string
  end
end

# frozen_string_literal: true

require "test_helper"

class TableDefinitionTest < ActiveSupport::TestCase
  setup do
    # Ensure PostGIS extension is enabled before running tests
    ActiveRecord::Base.connection.enable_extension("postgis") unless ActiveRecord::Base.connection.extension_enabled?("postgis")
    # Ensure PostGIS support is initialized
    ActiveRecord::ConnectionAdapters::PostGIS.initialize!
  end

  test "create table with spatial columns using table definition methods" do
    connection = ActiveRecord::Base.connection

    # Drop table if it exists before creating
    connection.drop_table :test_table_def_spatial, if_exists: true

    # Create table using spatial column methods
    connection.create_table :test_table_def_spatial do |t|
      t.st_point :location, srid: 4326  # srid via option
      t.st_line_string :path, srid: 4326, has_z: true  # srid + has_z
      t.st_polygon :area, srid: 3857  # different srid
      t.st_multi_point :points
      t.st_geometry :shape
      t.st_geography :region  # geography
    end

    # Verify the table was created with proper column types
    columns = connection.columns(:test_table_def_spatial)

    location_col = columns.find { |c| c.name == "location" }
    assert_equal "geometry(Point,4326)", location_col.sql_type

    path_col = columns.find { |c| c.name == "path" }
    assert_equal "geometry(LineStringZ,4326)", path_col.sql_type

    area_col = columns.find { |c| c.name == "area" }
    assert_equal "geometry(Polygon,3857)", area_col.sql_type

    points_col = columns.find { |c| c.name == "points" }
    assert_equal "geometry(MultiPoint)", points_col.sql_type

    shape_col = columns.find { |c| c.name == "shape" }
    assert_equal "geometry", shape_col.sql_type

    region_col = columns.find { |c| c.name == "region" }
    assert_equal "geography", region_col.sql_type
  ensure
    # Always clean up the table
    connection.drop_table :test_table_def_spatial, if_exists: true
  end
end

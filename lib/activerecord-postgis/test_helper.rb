# frozen_string_literal: true

require_relative "../active_record/connection_adapters/postgis/test_helpers"

module ActiveRecordPostgis
  module TestHelper
    include ActiveRecord::ConnectionAdapters::PostGIS::TestHelpers

    # Additional convenience methods for PostGIS testing
    def factory(srid: 4326, geographic: false)
      if geographic
        RGeo::Geographic.spherical_factory(srid: srid)
      else
        RGeo::Cartesian.preferred_factory(srid: srid)
      end
    end

    def geographic_factory(srid: 4326)
      RGeo::Geographic.spherical_factory(srid: srid)
    end

    def cartesian_factory(srid: 0)
      RGeo::Cartesian.preferred_factory(srid: srid)
    end

    def spatial_factory_store
      RGeo::ActiveRecord::SpatialFactoryStore.instance
    end

    def reset_spatial_store
      spatial_factory_store.clear
      spatial_factory_store.default = nil
    end

    # Create a test table with spatial columns
    def create_spatial_table(table_name, connection = ActiveRecord::Base.connection)
      connection.create_table table_name, force: true do |t|
        t.st_point :coordinates, srid: 4326
        t.st_point :location, srid: 4326, geographic: true
        t.st_polygon :boundary, srid: 4326
        t.st_line_string :path, srid: 4326
        t.timestamps
      end
    end

    # Clean up spatial tables after tests
    def drop_spatial_table(table_name, connection = ActiveRecord::Base.connection)
      connection.drop_table table_name if connection.table_exists?(table_name)
    end
  end
end

# frozen_string_literal: true

require_relative "postgis/version"
require_relative "postgis/type/geography"
require_relative "postgis/type/geometry"
require_relative "postgis/type/geometry_collection"
require_relative "postgis/type/line_string"
require_relative "postgis/type/multi_line_string"
require_relative "postgis/type/multi_point"
require_relative "postgis/type/multi_polygon"
require_relative "postgis/type/point"
require_relative "postgis/type/polygon"
require_relative "postgis/schema_dumper"
require_relative "postgis/table_definition"
require_relative "postgis/column_methods"
require_relative "postgis/schema_statements"
require_relative "postgis/spatial_column_type"
require_relative "postgis/adapter_extensions"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class Error < StandardError; end
      @initialized = false

      SPATIAL_TYPES_FOR_REGISTRATION = %i[
        st_geography st_geometry st_geometry_collection st_line_string st_multi_line_string
        st_multi_point st_multi_polygon st_point st_polygon
      ].freeze

      SPATIAL_OPTIONS_FOR_REGISTRATION = %i[srid has_z has_m geographic].freeze

      def self.initialize!
        return if @initialized
        @initialized = true

        # Allow PostGIS specific options in table definitions
        # The `define_column_methods` call already makes these available on the `TableDefinition` instance.
        # The issue might be deeper in how schema.rb is processed or how options are validated.
        # Let's ensure that the column methods are defined *before* any schema loading that might trigger validation.

        ActiveRecord::ConnectionAdapters::PostgreSQL::Table.include(
          ActiveRecord::ConnectionAdapters::PostGIS::TableDefinition
        )

        # Using st_* prefix to avoid conflicts with PostgreSQL native geometric types
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geography] = { name: "geography" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geometry] = { name: "geometry" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geometry_collection] = { name: "geometry(GeometryCollection)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_line_string] = { name: "geometry(LineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_line_string] = { name: "geometry(MultiLineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_point] = { name: "geometry(MultiPoint)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_polygon] = { name: "geometry(MultiPolygon)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_point] = { name: "geometry(Point)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_polygon] = { name: "geometry(Polygon)" }


        # Tell Rails these are valid column methods for schema dumping - PostgreSQL only
        ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.send(:define_column_methods,
                                                                            :st_geography, :st_geometry, :st_geometry_collection, :st_line_string,
                                                                            :st_multi_line_string, :st_multi_point, :st_multi_polygon, :st_point, :st_polygon, *SPATIAL_OPTIONS_FOR_REGISTRATION)

        # prevent unknown OID warning and register PostGIS types
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(RegisterTypes)

        # Prepend our extensions to handle spatial columns
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(AdapterExtensions)

        # Register spatial types with ActiveRecord::Type - use st_* prefix to avoid conflicts
        adapter_name = :postgresql

        SPATIAL_TYPES_FOR_REGISTRATION.each do |geo_type|
          ActiveRecord::Type.register(geo_type, Type::Spatial, adapter: adapter_name)
        end

        # Ignore PostGIS system tables in schema dumps - PostgreSQL specific
        ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_tables |= %w[
              geography_columns
              geometry_columns
              layer
              raster_columns
              raster_overviews
              spatial_ref_sys
              topology
            ]
      end

      module RegisterTypes
        def initialize_type_map(m = type_map)
          super

          # Register by type name for schema loading
          m.register_type "geography" do |_, _, sql_type|
            create_spatial_type_from_sql(sql_type)
          end

          m.register_type "geometry" do |_, _, sql_type|
            create_spatial_type_from_sql(sql_type)
          end
        end

        private

        def create_spatial_type_from_sql(sql_type)
          case sql_type
          when /geography\(Point/i, /geometry\(Point/i
            Type::Point.new
          when /geography\(LineString/i, /geometry\(LineString/i
            Type::LineString.new
          when /geography\(Polygon/i, /geometry\(Polygon/i
            Type::Polygon.new
          when /geography\(MultiPoint/i, /geometry\(MultiPoint/i
            Type::MultiPoint.new
          when /geography\(MultiLineString/i, /geometry\(MultiLineString/i
            Type::MultiLineString.new
          when /geography\(MultiPolygon/i, /geometry\(MultiPolygon/i
            Type::MultiPolygon.new
          when /geography\(GeometryCollection/i, /geometry\(GeometryCollection/i
            Type::GeometryCollection.new
          when /geography/i
            Type::Geography.new
          when /geometry/i
            Type::Geometry.new
          else
            Type::Geometry.new
          end
        end
      end
    end
  end
end

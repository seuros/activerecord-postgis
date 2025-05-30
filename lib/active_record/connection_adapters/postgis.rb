# frozen_string_literal: true

require "active_record/connection_adapters/postgresql_adapter"
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
require_relative "postgis/column_extensions"
require_relative "postgis/quoting"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class Error < StandardError; end
      @initialized = false

      SPATIAL_TYPES_FOR_REGISTRATION = %i[
        st_geography st_geometry st_geometry_collection st_line_string st_multi_line_string
        st_multi_point st_multi_polygon st_point st_polygon line_string
      ].freeze

      SPATIAL_OPTIONS_FOR_REGISTRATION = %i[srid has_z has_m geographic].freeze

      def self.initialize!
        return if @initialized
        @initialized = true

        # Extend PostgreSQL Column class with spatial functionality
        PostgreSQL::Column.include(ColumnExtensions)

        # Add spatial object quoting support
        PostgreSQLAdapter.prepend(Quoting)

        # Allow PostGIS specific options in table definitions
        # The `define_column_methods` call already makes these available on the `TableDefinition` instance.
        # The issue might be deeper in how schema.rb is processed or how options are validated.
        # Let's ensure that the column methods are defined *before* any schema loading that might trigger validation.

        PostgreSQL::Table.include(
          PostGIS::TableDefinition
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

        # Legacy aliases for compatibility with activerecord-postgis-adapter
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geography] = { name: "geography" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geometry] = { name: "geometry" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geometry_collection] = { name: "geometry(GeometryCollection)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:line_string] = { name: "geometry(LineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_line_string] = { name: "geometry(MultiLineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_point] = { name: "geometry(MultiPoint)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_polygon] = { name: "geometry(MultiPolygon)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:polygon] = { name: "geometry(Polygon)" }


        # Tell Rails these are valid column methods for schema dumping - PostgreSQL only
        PostgreSQL::TableDefinition.send(:define_column_methods,
                                                                            :st_geography, :st_geometry, :st_geometry_collection, :st_line_string,
                                                                            :st_multi_line_string, :st_multi_point, :st_multi_polygon, :st_point, :st_polygon,
                                                                            # Legacy column methods for compatibility with activerecord-postgis-adapter
                                                                            :geography, :geometry, :geometry_collection, :line_string,
                                                                            :multi_line_string, :multi_point, :multi_polygon, :polygon,
                                                                            *SPATIAL_OPTIONS_FOR_REGISTRATION)

        # prevent unknown OID warning and register PostGIS types
        PostgreSQLAdapter.singleton_class.prepend(RegisterTypes)

        # Prepend our extensions to handle spatial columns
        PostgreSQLAdapter.prepend(AdapterExtensions)

        # Register spatial types with ActiveRecord::Type - use st_* prefix to avoid conflicts
        adapter_name = :postgresql

        # Register specific spatial types with their corresponding classes
        ActiveRecord::Type.register(:st_geography, Type::Geography, adapter: adapter_name)
        ActiveRecord::Type.register(:st_geometry, Type::Geometry, adapter: adapter_name)
        ActiveRecord::Type.register(:st_geometry_collection, Type::GeometryCollection, adapter: adapter_name)
        ActiveRecord::Type.register(:st_line_string, Type::LineString, adapter: adapter_name)
        ActiveRecord::Type.register(:st_multi_line_string, Type::MultiLineString, adapter: adapter_name)
        ActiveRecord::Type.register(:st_multi_point, Type::MultiPoint, adapter: adapter_name)
        ActiveRecord::Type.register(:st_multi_polygon, Type::MultiPolygon, adapter: adapter_name)
        ActiveRecord::Type.register(:st_point, Type::Point, adapter: adapter_name)
        ActiveRecord::Type.register(:st_polygon, Type::Polygon, adapter: adapter_name)

        # Legacy type registrations for compatibility with activerecord-postgis-adapter
        ActiveRecord::Type.register(:geography, Type::Geography, adapter: adapter_name)
        ActiveRecord::Type.register(:geometry, Type::Geometry, adapter: adapter_name)
        ActiveRecord::Type.register(:geometry_collection, Type::GeometryCollection, adapter: adapter_name)
        ActiveRecord::Type.register(:line_string, Type::LineString, adapter: adapter_name)
        ActiveRecord::Type.register(:multi_line_string, Type::MultiLineString, adapter: adapter_name)
        ActiveRecord::Type.register(:multi_point, Type::MultiPoint, adapter: adapter_name)
        ActiveRecord::Type.register(:multi_polygon, Type::MultiPolygon, adapter: adapter_name)
        ActiveRecord::Type.register(:polygon, Type::Polygon, adapter: adapter_name)

        # Ignore PostGIS system tables in schema dumps - PostgreSQL specific
        PostgreSQL::SchemaDumper.ignore_tables |= %w[
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
          # Extract SRID and dimensions from SQL type
          srid = extract_srid_from_sql(sql_type)
          # Check for dimension suffixes (e.g., PointZ, PointM, PointZM)
          has_z = sql_type.match?(/\b\w+Z\b|\b\w+ZM\b/)
          has_m = sql_type.match?(/\b\w+M\b|\b\w+ZM\b/)
          geographic = sql_type.start_with?("geography")
          case sql_type
          when /geography\(Point/i
            Type::Point.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(Point/i
            Type::Point.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography\(LineString/i
            Type::LineString.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(LineString/i
            Type::LineString.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography\(Polygon/i
            Type::Polygon.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(Polygon/i
            Type::Polygon.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography\(MultiPoint/i
            Type::MultiPoint.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(MultiPoint/i
            Type::MultiPoint.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography\(MultiLineString/i
            Type::MultiLineString.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(MultiLineString/i
            Type::MultiLineString.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography\(MultiPolygon/i
            Type::MultiPolygon.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(MultiPolygon/i
            Type::MultiPolygon.new(srid: srid, has_z: has_z, has_m: has_m, geographic: false)
          when /geography\(GeometryCollection/i
            Type::GeometryCollection.new(srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          when /geometry\(GeometryCollection/i
            Type::GeometryCollection.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geography/i
            Type::Geography.new(srid: srid, has_z: has_z, has_m: has_m)
          when /geometry/i
            Type::Geometry.new(srid: srid, has_z: has_z, has_m: has_m)
          else
            Type::Geometry.new(srid: srid, has_z: has_z, has_m: has_m)
          end
        end

        def extract_srid_from_sql(sql_type)
          # Extract SRID from patterns like geometry(Point,3785) or geography(Point,4326)
          match = sql_type.match(/,(\d+)\)/)
          match ? match[1].to_i : 0
        end
      end
    end
  end
end

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
require_relative "postgis/spatial_queries"
require_relative "postgis/database_statements"

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

        extend_postgresql_adapter

        register_spatial_types

        ignore_postgis_system_tables
      end

      def self.extend_postgresql_adapter
        PostgreSQL::Column.include(ColumnExtensions)
        PostgreSQLAdapter.prepend(Quoting)
        PostgreSQL::Table.include(PostGIS::TableDefinition)
        PostgreSQLAdapter.prepend(AdapterExtensions)
        PostgreSQLAdapter.prepend(DatabaseStatements)
      end

      def self.register_spatial_types
        register_native_database_types
        register_column_methods
        register_type_classes
        register_type_mapping
      end

      def self.register_native_database_types
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geography] = { name: "geography" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geometry] = { name: "geometry" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_geometry_collection] = { name: "geometry(GeometryCollection)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_line_string] = { name: "geometry(LineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_line_string] = { name: "geometry(MultiLineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_point] = { name: "geometry(MultiPoint)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_multi_polygon] = { name: "geometry(MultiPolygon)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_point] = { name: "geometry(Point)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:st_polygon] = { name: "geometry(Polygon)" }

        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geography] = { name: "geography" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geometry] = { name: "geometry" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:geometry_collection] = { name: "geometry(GeometryCollection)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:line_string] = { name: "geometry(LineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_line_string] = { name: "geometry(MultiLineString)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_point] = { name: "geometry(MultiPoint)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:multi_polygon] = { name: "geometry(MultiPolygon)" }
        PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:polygon] = { name: "geometry(Polygon)" }
      end

      def self.register_column_methods
        PostgreSQL::TableDefinition.send(:define_column_methods,
          :st_geography, :st_geometry, :st_geometry_collection, :st_line_string,
          :st_multi_line_string, :st_multi_point, :st_multi_polygon, :st_point, :st_polygon,
          :geography, :geometry, :geometry_collection, :line_string,
          :multi_line_string, :multi_point, :multi_polygon, :polygon,
          *SPATIAL_OPTIONS_FOR_REGISTRATION)
      end

      def self.register_type_classes
        adapter_name = :postgresql

        SPATIAL_TYPES_FOR_REGISTRATION.each do |type_name|
          type_class_name = type_name.to_s.sub(/^st_/, "").split("_").map(&:capitalize).join
          type_class = Type.const_get(type_class_name) rescue nil
          if type_class
            ActiveRecord::Type.register(type_name, type_class, adapter: adapter_name)
          end
        end
      end

      def self.register_type_mapping
        if PostgreSQLAdapter.respond_to?(:register_type_mapping)
          PostgreSQLAdapter.register_type_mapping { |m| TypeRegistration.register!(m) }
        else
          PostgreSQLAdapter.singleton_class.prepend(RegisterTypes)
        end
      end

      def self.ignore_postgis_system_tables
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

      module TypeRegistration
        def self.register!(m)
          m.register_type("geometry") { |_, _, sql| from_sql(sql) }
          m.register_type("geography") { |_, _, sql| from_sql(sql) }
        end

        def self.from_sql(sql_type)
          if sql_type.nil? || sql_type.empty?
            return Type::Geometry.new(srid: 0, has_z: false, has_m: false, geographic: false)
          end

          srid = extract_srid_from_sql(sql_type)
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

        def self.extract_srid_from_sql(sql_type)
          match = sql_type.match(/,(\d+)\)/)
          match ? match[1].to_i : 0
        end
      end

      module RegisterTypes
        def initialize_type_map(m = type_map)
          super
          TypeRegistration.register!(m)
        end
      end
    end
  end
end

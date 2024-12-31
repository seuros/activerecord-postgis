# frozen_string_literal: true

require "rgeo-activerecord"
require "active_record/connection_adapters"
require "active_record/connection_adapters/postgresql_adapter"
require "active_record/connection_adapters/postgresql/schema_dumper.rb"
require_relative "active_record/connection_adapters/postgis"

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      NATIVE_DATABASE_TYPES[:st_geography] = { name: "geography" }
      NATIVE_DATABASE_TYPES[:st_geometry] = { name: "geometry" }
      NATIVE_DATABASE_TYPES[:st_geometry_collection] = { name: "geometry_collection" }
      NATIVE_DATABASE_TYPES[:st_line_string] = { name: "line_string" }
      NATIVE_DATABASE_TYPES[:st_multi_line_string] = { name: "multi_line_string" }
      NATIVE_DATABASE_TYPES[:st_multi_point] = { name: "multi_point" }
      NATIVE_DATABASE_TYPES[:st_multi_polygon] = { name: "multi_polygon" }
      NATIVE_DATABASE_TYPES[:st_point] = { name: "point" }
      NATIVE_DATABASE_TYPES[:st_polygon] = { name: "polygon" }

      def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, **options)
        if type.to_s =~ /^st_/
          # Convert st_* types to their base spatial types
          geometric_type = type.to_s.sub(/^st_/, '')
          geographic = options[:geographic] || scale # geographic flag can be in options or scale
          srid = options[:srid] || limit # SRID can be in options or limit
          has_z = options[:has_z] || precision # has_z can be in options or precision
          has_m = options[:has_m] # has_m is only in options

          PostGIS::SpatialColumnType.new(
            geometric_type,
            srid,
            has_z: has_z,
            has_m: has_m,
            geography: geographic
          ).to_sql
        else
          super
        end
      end
    end

    module PostgreSQL
      SchemaCreation.class_eval do
        def visit_ColumnDefinition(o)
          sql = super
          if sql.is_a?(String) && o.type.to_s =~ /^st_/
            sql = sql.sub(/"([^"]+)" ([^,]+)/) do |match|
              column_name = Regexp.last_match(1)
              type_sql = type_to_sql(o.type.to_sym,
                                     limit: o.limit,
                                     precision: o.precision,
                                     scale: o.scale,
                                     array: o.array,
                                     geographic: o.scale, # Using scale for geographic flag
                                     has_z: o.precision) # Using precision for has_z flag
              "\"#{column_name}\" #{type_sql}"
            end
          end
          sql
        end
      end

      TableDefinition.include PostGIS::SpatialColumnMethods
      Table.include PostGIS::SpatialColumnMethods
    end
  end
end
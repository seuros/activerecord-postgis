# frozen_string_literal: true

require "rgeo-activerecord"
require "active_record/connection_adapters/postgresql_adapter"
require "active_record/connection_adapters/postgis/spatial_column_methods"
require "active_record/connection_adapters/postgis/spatial_column_type"

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      NATIVE_DATABASE_TYPES[:st_geography] = { name: "geography" }
      NATIVE_DATABASE_TYPES[:st_geometry] = { name: "geometry" }
      NATIVE_DATABASE_TYPES[:st_geometry_collection] = { name: "geometry(GeometryCollection)" }
      NATIVE_DATABASE_TYPES[:st_line_string] = { name: "geometry(LineString)" }
      NATIVE_DATABASE_TYPES[:st_multi_line_string] = { name: "geometry(MultiLineString)" }
      NATIVE_DATABASE_TYPES[:st_multi_point] = { name: "geometry(MultiPoint)" }
      NATIVE_DATABASE_TYPES[:st_multi_polygon] = { name: "geometry(MultiPolygon)" }
      NATIVE_DATABASE_TYPES[:st_point] = { name: "geometry(Point)" }
      NATIVE_DATABASE_TYPES[:st_polygon] = { name: "geometry(Polygon)" }

      def type_to_sql(type, limit: nil, precision: nil, scale: nil, array: nil, srid: nil, geographic: false,
                      has_z: false, has_m: false, **)
        normalized_type = type.to_s.downcase

        if spatial_type?(normalized_type)
          geometry_type = extract_geometry_type(normalized_type)
          spatial_type_sql(geometry_type, srid, geographic, has_z, has_m)
        else
          super
        end
      end

      private

      def spatial_type?(type)
        type.start_with?("st_") || type =~ /^(geometry|geography)/i
      end

      def extract_geometry_type(type)
        type.start_with?("st_") ? type.sub("st_", "") : type
      end

      def spatial_type_sql(geometry_type, srid, geographic, has_z, has_m)
        spatial_column = ActiveRecord::ConnectionAdapters::PostGIS::SpatialColumnType.new(
          geometry_type,
          srid,
          has_z: has_z,
          has_m: has_m,
          geography: geographic
        )
        spatial_column.to_sql
      end

      def column_spec_for_primary_key(column)
        spec = super
        spec[:type] = column.sql_type.to_sym if column.sql_type =~ /^(geography|geometry)/i
        spec
      end

      def add_dimensions(base_type, has_z, has_m)
        return base_type unless has_z || has_m

        type_name, type_args = base_type.split("(")
        dimension_suffix = case [ has_z, has_m ]
        when [ true, true ] then "ZM"
        when [ true, false ] then "Z"
        when [ false, true ] then "M"
        end

        if type_args
          "#{type_name}(#{type_args.chomp(')')}#{dimension_suffix})"
        else
          "#{base_type}#{dimension_suffix}"
        end
      end
    end

    module PostgreSQL
      SchemaDumper.ignore_tables |= %w[
        geography_columns
        geometry_columns
        layer
        raster_columns
        raster_overviews
        spatial_ref_sys
        topology
      ]

      SpatialColumnMethods = PostGIS::SpatialColumnMethods
      TableDefinition.include SpatialColumnMethods
      Table.include SpatialColumnMethods
    end
  end
end

# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module ColumnMethods
        # Override to handle PostGIS types in column definitions
        def new_column_from_field(table_name, field, _definitions)
          column_name = field["column_name"]
          type_metadata = fetch_type_metadata(column_name, field["data_type"], field["sql_type"], field)

          # Handle PostGIS types
          if field["sql_type"] =~ /geometry|geography/i
            type_metadata = handle_spatial_type_metadata(field["sql_type"], type_metadata)
          end

          default_value = extract_value_from_default(field["column_default"])
          default_function = extract_default_function(field["column_default"], default_value)

          PostgreSQL::Column.new(
            column_name,
            default_value,
            type_metadata,
            field["is_nullable"] == "YES",
            default_function,
            comment: field["comment"].presence
          )
        end

        private

        def handle_spatial_type_metadata(sql_type, original_metadata)
          # Parse spatial type info
          type_name = case sql_type
          when /geography\(Point/i, /geometry\(Point/i then "point"
          when /geography\(LineString/i, /geometry\(LineString/i then "line_string"
          when /geography\(Polygon/i, /geometry\(Polygon/i then "polygon"
          when /geography\(MultiPoint/i, /geometry\(MultiPoint/i then "multi_point"
          when /geography\(MultiLineString/i, /geometry\(MultiLineString/i then "multi_line_string"
          when /geography\(MultiPolygon/i, /geometry\(MultiPolygon/i then "multi_polygon"
          when /geography\(GeometryCollection/i, /geometry\(GeometryCollection/i then "geometry_collection"
          when /geography/i then "geography"
          when /geometry/i then "geometry"
          else
                        return original_metadata
          end

          # Create new type metadata with spatial type
          type = ActiveRecord::Type.lookup(type_name.to_sym, adapter: adapter_name.downcase.to_sym)
          ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
            sql_type: sql_type,
            type: type,
            limit: original_metadata.limit,
            precision: original_metadata.precision,
            scale: original_metadata.scale
          )
        end
      end
    end
  end
end

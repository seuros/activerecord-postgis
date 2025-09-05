# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaStatements
        # Override to handle PostGIS column types
        def columns(table_name)
          column_definitions(table_name).map do |field|
            new_column_from_field(table_name, field, @type_map)
          end
        end

        # Override column type lookup to handle PostGIS types
        def column_type_for(column_name)
          column_name = column_name.to_s

          # Check if it's a known PostGIS type
          if column_name =~ /^(geometry|geography)/
            # Extract the base type name from definitions like "geometry(Point,4326)"
            base_type = case column_name
            when /\(Point/i then :point
            when /\(LineString/i then :line_string
            when /\(Polygon/i then :polygon
            when /\(MultiPoint/i then :multi_point
            when /\(MultiLineString/i then :multi_line_string
            when /\(MultiPolygon/i then :multi_polygon
            when /\(GeometryCollection/i then :geometry_collection
            when /^geography/i then :geography
            when /^geometry/i then :geometry
            else
                          nil
            end

            return base_type if base_type
          end

          super
        end

        private

        # Override to handle PostGIS types in column fetching
        def column_definitions(table_name)
          query = <<~SQL
            SELECT#{' '}
              a.attname AS column_name,
              format_type(a.atttypid, a.atttypmod) AS sql_type,
              pg_get_expr(d.adbin, d.adrelid) AS column_default,
              a.attnotnull AS not_null,
              a.atttypid AS type_id,
              a.atttypmod AS type_mod,
              c.collname AS collation,
              col_description(pg_class.oid, a.attnum) AS comment,
              #{supports_identity_columns? ? 'attidentity' : quote('')} AS identity,
              #{supports_virtual_columns? ? 'attgenerated' : quote('')} AS attgenerated
            FROM pg_attribute a
            LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
            LEFT JOIN pg_type t ON a.atttypid = t.oid
            LEFT JOIN pg_collation c ON a.attcollation = c.oid
            JOIN pg_class ON pg_class.oid = a.attrelid
            WHERE a.attrelid = #{quote(quote_table_name(table_name))}::regclass
              AND a.attnum > 0
              AND NOT a.attisdropped
            ORDER BY a.attnum
          SQL

          execute_and_clear(query, "SCHEMA", allow_retry: true, uses_transaction: false) do |result|
            result.map do |row|
              {
                "column_name" => row["column_name"],
                "sql_type" => row["sql_type"],
                "type_id" => row["type_id"],
                "type_mod" => row["type_mod"],
                "column_default" => row["column_default"],
                "is_nullable" => row["not_null"] == "f" ? "YES" : "NO",
                "collation" => row["collation"],
                "comment" => row["comment"],
                "identity" => row["identity"],
                "attgenerated" => row["attgenerated"]
              }
            end
          end
        end

        # Create column from field data, handling PostGIS types
        def new_column_from_field(table_name, field, type_map)
          type_metadata = fetch_type_metadata(field["column_name"], field["sql_type"], field, type_map)
          default_value = extract_value_from_default(field["column_default"])
          default_function = extract_default_function(field["column_default"], default_value)

          PostgreSQL::Column.new(
            field["column_name"],
            type_metadata.type,
            default_value,
            type_metadata,
            field["is_nullable"] == "YES",
            default_function,
            comment: field["comment"].presence,
            identity: field["identity"].presence
          )
        end

        # Fetch type metadata, handling PostGIS types
        def fetch_type_metadata(column_name, sql_type, field, type_map)
          cast_type = if sql_type =~ /^(geometry|geography)/i
                        # Handle PostGIS types
                        type_name = case sql_type
                        when /\(Point/i then :point
                        when /\(LineString/i then :line_string
                        when /\(Polygon/i then :polygon
                        when /\(MultiPoint/i then :multi_point
                        when /\(MultiLineString/i then :multi_line_string
                        when /\(MultiPolygon/i then :multi_polygon
                        when /\(GeometryCollection/i then :geometry_collection
                        when /^geography/i then :geography
                        when /^geometry/i then :geometry
                        end

                        lookup_cast_type(type_name.to_s)
          else
                        type_map.fetch(field["type_id"].to_i, field["type_mod"].to_i) do
                          lookup_cast_type(sql_type)
                        end
          end

          simple_type = SqlTypeMetadata.new(
            sql_type: sql_type,
            type: cast_type
          )

          PostgreSQL::TypeMetadata.new(simple_type)
        end
      end
    end
  end
end

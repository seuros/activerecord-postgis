# lib/active_record/connection_adapters/postgis/schema_dumper.rb

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      SchemaDumper.class_eval do
        # Initialize the ignore tables set if it hasn't been already
        # Add PostGIS system tables to the ignore list
        self.ignore_tables +=
          %w[
            geography_columns
            geometry_columns
            layer
            raster_columns
            raster_overviews
            spatial_ref_sys
            topology
          ]
      end
    end

    module PostGIS
      module SchemaDumper
        def schema_type(column)
          if column.sql_type =~ /^(geometry|geography)/i
            geo_type, srid, has_z, has_m, geographic = PostGIS::OID::Spatial.parse_sql_type(column.sql_type)

            if geographic
              :st_geography
            else
              case geo_type&.downcase
              when "point" then :st_point
              when "linestring" then :st_line_string
              when "polygon" then :st_polygon
              when "multipoint" then :st_multi_point
              when "multilinestring" then :st_multi_line_string
              when "multipolygon" then :st_multi_polygon
              when "geometrycollection" then :st_geometry_collection
              else :st_geometry
              end
            end
          else
            super
          end
        end

        def prepare_column_options(column)
          spec = super

          if column.sql_type =~ /^(geometry|geography)/i
            geo_type, srid, has_z, has_m, geographic = PostGIS::OID::Spatial.parse_sql_type(column.sql_type)
            spec[:srid] = srid if srid > 0
            spec[:geographic] = true if geographic
            spec[:has_z] = true if has_z
            spec[:has_m] = true if has_m
          end

          spec
        end

        def column_spec_string(column)
          spec = prepare_column_options(column)
          spec_string = []

          if column.sql_type =~ /^(geometry|geography)/i
            # For spatial columns, use the raw SQL type
            spec_string << "\"#{column.sql_type}\""
          else
            spec_string << schema_type(column).inspect
          end

          spec_string << "null: false" if !column.null
          spec_string << "default: #{schema_default(column).inspect}" if column.default

          spec_string.join(', ')
        end
      end
    end

    PostgreSQL::SchemaDumper.prepend(PostGIS::SchemaDumper)
  end
end
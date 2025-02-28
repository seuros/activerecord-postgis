# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SchemaDumper
        private

        # Tell Rails these are valid column types that should use method syntax
        def valid_column_spec?(column)
          return true if column.sql_type =~ /^(geometry|geography)/i
          super
        end

        def column_spec_for_primary_key(column)
          return super unless column.sql_type =~ /^(geometry|geography)/i
          spec = { id: column.name }
          spec[:type] = schema_type(column).to_sym
          extract_spatial_options(column, spec)
          spec
        end

        def prepare_column_options(column)
          spec = super

          if column.sql_type =~ /^(geometry|geography)/i
            extract_spatial_options(column, spec)
          end

          spec
        end

        # Override to return our spatial types
        def schema_type(column)
          if column.sql_type =~ /^(geometry|geography)/i
            case column.sql_type
            when /geography\(Point/i, /geometry\(Point/i
              :st_point
            when /geography\(LineString/i, /geometry\(LineString/i
              :st_line_string
            when /geography\(Polygon/i, /geometry\(Polygon/i
              :st_polygon
            when /geography\(MultiPoint/i, /geometry\(MultiPoint/i
              :st_multi_point
            when /geography\(MultiLineString/i, /geometry\(MultiLineString/i
              :st_multi_line_string
            when /geography\(MultiPolygon/i, /geometry\(MultiPolygon/i
              :st_multi_polygon
            when /geography\(GeometryCollection/i, /geometry\(GeometryCollection/i
              :st_geometry_collection
            when /geography/i
              :st_geography
            when /geometry/i
              :st_geometry
            end
          else
            super
          end
        end

        def extract_spatial_options(column, spec)
          if column.sql_type =~ /^(geometry|geography)\(([^,\)]+)(?:,(\d+))?\)/i
            spatial_type = $1
            geom_type = $2
            srid = $3&.to_i

            # Add SRID if not default
            if srid && srid != default_srid(spatial_type)
              spec[:srid] = srid
            end

            # Check for dimension modifiers
            if geom_type =~ /^(\w+?)(Z|M|ZM)$/i
              dimensions = $2.upcase
              spec[:has_z] = true if dimensions.include?("Z")
              spec[:has_m] = true if dimensions.include?("M")
            end
          end
        end

        def default_srid(spatial_type)
          spatial_type.downcase == "geography" ? 4326 : 0
        end
      end
    end

    # Prepend to PostgreSQL's SchemaDumper
    module PostgreSQL
      class SchemaDumper
        prepend PostGIS::SchemaDumper
      end
    end
  end
end

# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module AdapterExtensions
        # Override type_to_sql to handle PostGIS spatial types
        def type_to_sql(type, limit: nil, precision: nil, scale: nil, geographic: false, srid: nil, has_z: false, has_m: false, **options)
          if type.to_s =~ /^st_/ || type.to_s == "geography"
            geometric_type = type.to_s.sub(/^st_/, "")

            # If limit contains our custom format, parse it
            if limit.is_a?(String) && limit.include?(",")
              geo_part, srid_part = limit.split(",", 2)
              # Extract geometry type from the limit if provided
              if geo_part && !geo_part.empty? && geo_part != geometric_type.upcase
                geometric_type = geo_part.downcase
              end
              # Extract SRID from limit
              if srid_part && !srid_part.empty?
                srid = srid_part.to_i
              end
              # Extract Z/M modifiers
              if geo_part && geo_part.include?("Z")
                has_z = true
                geometric_type = geo_part.gsub(/[ZM]/, "").downcase
              end
              if geo_part && geo_part.include?("M")
                has_m = true
                geometric_type = geo_part.gsub(/[ZM]/, "").downcase
              end
            end

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

        # Override to handle PostGIS types
        def lookup_cast_type(sql_type)
          # Handle PostGIS types
          if sql_type.to_s =~ /^(geometry|geography)/i
            type_name = case sql_type.to_s
            when /geography\(Point/i, /geometry\(Point/i then :st_point
            when /geography\(LineString/i, /geometry\(LineString/i then :st_line_string
            when /geography\(Polygon/i, /geometry\(Polygon/i then :st_polygon
            when /geography\(MultiPoint/i, /geometry\(MultiPoint/i then :st_multi_point
            when /geography\(MultiLineString/i, /geometry\(MultiLineString/i then :st_multi_line_string
            when /geography\(MultiPolygon/i, /geometry\(MultiPolygon/i then :st_multi_polygon
            when /geography\(GeometryCollection/i, /geometry\(GeometryCollection/i then :st_geometry_collection
            when /geography/i then :st_geography
            when /geometry/i then :st_geometry
            else
                          :st_geometry
            end

            ActiveRecord::Type.lookup(type_name, adapter: adapter_name.downcase.to_sym)
          else
            super
          end
        end

        # Override create_table_definition to use our custom table definition
        def create_table_definition(*args, **kwargs)
          table_def = super(*args, **kwargs)
          table_def.extend(PostGIS::TableDefinition)
          table_def
        end
      end
    end
  end
end

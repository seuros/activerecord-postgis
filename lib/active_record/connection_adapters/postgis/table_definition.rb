# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module TableDefinition
        # Define spatial column methods
        %i[st_point st_line_string st_polygon st_multi_point
           st_multi_line_string st_multi_polygon st_geometry_collection
           st_geometry st_geography].each do |spatial_type|
          define_method(spatial_type) do |name, **options|
            column(name, spatial_type, **options)
          end
        end

        # Override new_column_definition to handle spatial column options
        def new_column_definition(name, type, **options)
          col_type = if type.to_sym == :virtual
            options[:type]
          else
            type
          end

          if spatial_column_type?(col_type)
            if (limit = options.delete(:limit)) && limit.is_a?(::Hash)
              options.merge!(limit)
            end

            # Set geographic option for geography types
            if col_type.to_sym == :st_geography || col_type.to_sym == :geography
              options[:geographic] = true
            end

            geo_type = ColumnDefinitionUtils.geo_type(options[:type] || type)
            base_type = determine_base_type(col_type, options)

            options[:limit] = ColumnDefinitionUtils.limit_from_options(geo_type, options)
            options[:spatial_type] = geo_type
            column = super(name, base_type, **options)
          else
            column = super(name, type, **options)
          end

          column
        end

        private

        # Allow spatial-specific options in column definitions
        def valid_column_definition_options
          super + [ :srid, :has_z, :has_m, :geographic, :spatial_type ]
        end

        def spatial_column_type?(type)
          type.to_s.start_with?("st_") || [ :geography, :geometry ].include?(type.to_sym)
        end

        def determine_base_type(col_type, options)
          case col_type.to_sym
          when :st_geography, :geography
            :st_geography
          else
            # Only use geography if explicitly requested
            if options[:geographic] == true
              :st_geography
            else
              # Preserve the specific geometry type
              col_type.to_sym
            end
          end
        end
      end

      # Custom table definition class that includes spatial support
      class SpatialTableDefinition < ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition
        include TableDefinition
      end

      module ColumnDefinitionUtils
        class << self
          def geo_type(type = "GEOMETRY")
            g_type = type.to_s.delete("_").upcase
            case g_type
            when "STPOINT" then "POINT"
            when "STPOLYGON" then "POLYGON"
            when "STLINESTRING" then "LINESTRING"
            when "STMULTIPOINT" then "MULTIPOINT"
            when "STMULTILINESTRING" then "MULTILINESTRING"
            when "STMULTIPOLYGON" then "MULTIPOLYGON"
            when "STGEOMETRYCOLLECTION" then "GEOMETRYCOLLECTION"
            when "STGEOMETRY" then "GEOMETRY"
            when "STGEOGRAPHY" then "GEOGRAPHY"
            else
              "GEOMETRY"  # Default fallback
            end
          end

          def limit_from_options(type, options = {})
            has_z = options[:has_z] ? "Z" : ""
            has_m = options[:has_m] ? "M" : ""
            srid = options[:srid] || default_srid(options)
            field_type = [ type, has_z, has_m ].compact.join
            "#{field_type},#{srid}"
          end

          def default_srid(options)
            # Geography columns default to SRID 4326, geometry columns to 0
            options[:geographic] ? 4326 : 0
          end
        end
      end
    end
  end
end

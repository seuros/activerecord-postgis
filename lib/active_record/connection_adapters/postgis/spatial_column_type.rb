# frozen_string_literal: true

require "active_record/connection_adapters/postgresql_adapter"

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      SchemaCreation.class_eval do
        private

        def visit_ColumnDefinition(o)
          if o.type.to_s =~ /^st_/
            # Parse options from limit if it's our custom format
            srid = nil
            has_z = false
            has_m = false
            geographic = false

            if o.limit.is_a?(String) && o.limit.include?(",")
              geo_part, srid_part = o.limit.split(",", 2)
              srid = srid_part.to_i if srid_part && !srid_part.empty?
              if geo_part
                # Check for Z and M dimensions at the end of the geometry type
                has_z = geo_part.end_with?("Z") || geo_part.end_with?("ZM")
                has_m = geo_part.end_with?("M") || geo_part.end_with?("ZM")
              end
            else
              # Use individual column options if available
              srid = o.options[:srid] if o.options.key?(:srid)
              has_z = o.options[:has_z] if o.options.key?(:has_z)
              has_m = o.options[:has_m] if o.options.key?(:has_m)
              geographic = o.options[:geographic] if o.options.key?(:geographic)
            end

            sql_type = type_to_sql(o.type.to_sym,
                                   limit: o.limit,
                                   precision: o.precision,
                                   scale: o.scale,
                                   srid: srid,
                                   geographic: geographic,
                                   has_z: has_z,
                                   has_m: has_m)
            column_sql = "#{quote_column_name(o.name)} #{sql_type}"
            add_column_options!(column_sql, column_options(o))
            column_sql
          else
            super
          end
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, geographic: false, srid: nil, has_z: false, has_m: false, **options)
          if type.to_s =~ /^st_/
            geometric_type = type.to_s.sub(/^st_/, "")
            # Only use geography if explicitly requested via type or option
            is_geography = type.to_s == "st_geography" || geographic == true
            PostGIS::SpatialColumnType.new(
              geometric_type,
              srid,
              has_z: has_z,
              has_m: has_m,
              geography: is_geography
            ).to_sql
          else
            super(type, limit: limit, precision: precision, scale: scale, **options)
          end
        end
      end
    end

    module PostGIS
      class SpatialColumnType
        VALID_TYPES = %w[
          point line_string polygon multi_point
          multi_line_string multi_polygon geometry_collection geography geometry
        ].freeze

        attr_reader :type, :srid, :has_z, :has_m, :geography

        def initialize(type, srid = nil, has_z: false, has_m: false, geography: false)
          @type = type.to_s.downcase
          @srid = srid
          @has_z = has_z
          @has_m = has_m
          @geography = geography || @type == "geography"

          validate_type!
          validate_srid!
          validate_dimensions!
        end

        def to_sql
          base_type = @geography ? "geography" : "geometry"
          return base_type if @type == "geography"

          type_with_dimensions = build_type_with_dimensions
          if @srid && base_type == "geometry"
            "#{base_type}(#{type_with_dimensions},#{@srid})"
          else
            "#{base_type}(#{type_with_dimensions})"
          end
        end

        private

        def validate_type!
          unless VALID_TYPES.include?(@type)
            raise ArgumentError, "Invalid geometry type: #{@type}. Valid types are: #{VALID_TYPES.join(', ')}"
          end
        end

        def validate_srid!
          return unless @srid

          if @geography && @srid != 4326
            raise ArgumentError, "Invalid SRID for geography type: #{@srid}. The SRID must be 4326 or nil."
          end

          unless @srid.is_a?(Integer) && @srid >= 0 && @srid <= 999_999
            raise ArgumentError, "Invalid SRID #{@srid}. The SRID must be within the range 0-999999."
          end
        end

        def validate_dimensions!
          # All geometry types can have Z, M, or ZM dimensions
        end

        def build_type_with_dimensions
          type_name = @type.camelize
          if @has_z && @has_m
            type_name += "ZM"
          elsif @has_z
            type_name += "Z"
          elsif @has_m
            type_name += "M"
          end
          type_name
        end
      end
    end
  end
end

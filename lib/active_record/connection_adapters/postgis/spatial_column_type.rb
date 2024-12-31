# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      SchemaCreation.class_eval do
        private

        def visit_ColumnDefinition(o)
          if o.type.to_s =~ /^st_/
            sql_type = type_to_sql(o.type.to_sym,
                                   limit: o.limit,
                                   precision: o.precision,
                                   scale: o.scale,
                                   srid: o.limit,
                                   geographic: o.scale,
                                   has_z: o.precision)
            column_sql = "#{quote_column_name(o.name)} #{sql_type}"
            add_column_options!(column_sql, column_options(o))
            column_sql
          else
            super
          end
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, geographic: false, srid: nil, has_z: false, has_m: false, **options)
          if type.to_s =~ /^st_/
            geometric_type = type.to_s.sub(/^st_/, '')
            PostGIS::SpatialColumnType.new(
              geometric_type,
              srid,
              has_z: has_z,
              has_m: has_m,
              geography: geographic
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
          multi_line_string multi_polygon geometry_collection geography
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
          if @has_z && @has_m && @type != "point"
            raise ArgumentError, "Only point type supports both Z and M dimensions"
          end
        end

        def build_type_with_dimensions
          type_name = @type.camelize
          type_name += "Z" if @has_z
          type_name += "M" if @has_m
          type_name
        end
      end
    end
  end
end

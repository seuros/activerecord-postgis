# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SpatialColumnType
        attr_reader :type, :srid, :has_z, :has_m, :geography

        # Initialize with geometry type, SRID, dimensions, and geography flag
        def initialize(type, srid = nil, has_z: false, has_m: false, geography: false)
          @type = type.to_s.downcase
          @srid = srid
          @has_z = has_z
          @has_m = has_m
          @geography = geography
          @geography = true if @type == "geography"

          validate_type!
          validate_srid!
          validate_dimensions!
        end

        # Render the spatial type to SQL
        def to_sql
          base_type = @geography ? "geography" : "geometry"

          return base_type if @type == "geography"

          # Add type and dimensions if applicable
          type_with_dimensions = add_type_and_dimensions(base_type)
          # Append SRID if provided (skip for geography type)
          type_with_srid = append_srid(type_with_dimensions)
          type_with_srid.end_with?(")") ? type_with_srid : "#{type_with_srid})"
        end

        private

        # Validate the geometry type during initialization
        def validate_type!
          valid_types = %w[
        point line_string polygon multi_point
        multi_line_string multi_polygon geometry_collection geography
      ]
          unless valid_types.include?(@type)
            raise ArgumentError, "Invalid geometry type: #{@type}. Valid types are: #{valid_types.join(', ')}"
          end
        end

        # Validate the SRID for geography and geometry types
        def validate_srid!
          if @geography
            # For geography types, the SRID must be 4326 or nil
            if @srid && @srid != 4326
              raise ArgumentError, "Invalid SRID for geography type: #{@srid}. The SRID must be 4326 or nil."
            end
          else
            # For geometry types, validate that the SRID is within a valid range if provided
            if @srid && !(0..999_999).include?(@srid)
              raise ArgumentError, "Invalid SRID #{@srid}. The SRID must be within the range 0-999999."
            end
          end
        end

        # Validate dimensions
        def validate_dimensions!
          if @has_z && @has_m && @type != "point"
            raise ArgumentError, "Only point type supports both Z and M dimensions"
          end
        end

        # Append SRID if provided
        def append_srid(base_type)
          return base_type if @geography
          @srid ? "#{base_type},#{@srid}" : base_type
        end

        # Add type, Z and M dimensions if specified
        def add_type_and_dimensions(base_type)
          type_with_dimensions = @type.camelize
          type_with_dimensions += "Z" if @has_z
          type_with_dimensions += "M" if @has_m

          "#{base_type}(#{type_with_dimensions}"
        end
      end
    end
  end
end

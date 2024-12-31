# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SpatialColumnMethods
        extend ActiveSupport::Concern

        included do
          define_column_methods(*GEOMETRIC_TYPES)
        end

        private
        # We reuse existing column definition options:
        # - limit: SRID value
        # - precision: has_z flag
        # - scale: true for geography, false/nil for geometry
        # + standard options like null, default, comment, etc.
        def validate_column_definition(column_type, options)
          super

          return unless GEOMETRIC_TYPES.include?(column_type.to_sym)

          if options[:limit] # SRID validation
            srid = options[:limit]
            if options[:scale] # geography type
              unless srid == 4326
                raise ArgumentError, "Geography columns only support SRID 4326. Got: #{srid}"
              end
            else # geometry type
              unless srid.is_a?(Integer) && srid >= 0 && srid <= 999999
                raise ArgumentError, "SRID must be between 0 and 999999. Got: #{srid}"
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Quoting
        def quote(value)
          if value.is_a?(RGeo::Feature::Instance)
            # Convert spatial objects to EWKT format for PostgreSQL
            if value.srid && value.srid != 0
              "'SRID=#{value.srid};#{value.as_text}'"
            else
              "'#{value.as_text}'"
            end
          else
            super
          end
        end

        def type_cast(value)
          if RGeo::Feature::Geometry.check_type(value)
            # Use EWKB format to preserve SRID information
            RGeo::WKRep::WKBGenerator.new(
              hex_format: true,
              type_format: :ewkb,
              emit_ewkb_srid: true
            ).generate(value)
          elsif value.is_a?(RGeo::Cartesian::BoundingBox)
            value.to_s
          else
            super
          end
        end
      end
    end
  end
end

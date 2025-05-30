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
          if value.is_a?(RGeo::Feature::Instance)
            # Convert spatial objects to EWKT string for parameter binding
            if value.srid && value.srid != 0
              "SRID=#{value.srid};#{value.as_text}"
            else
              value.as_text
            end
          else
            super
          end
        end
      end
    end
  end
end

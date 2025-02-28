# frozen_string_literal: true

require_relative "spatial"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class MultiLineString < Spatial
          def initialize(srid: 0, has_z: false, has_m: false)
            super(geo_type: "multi_line_string", srid: srid, has_z: has_z, has_m: has_m)
          end

          def type
            :st_multi_line_string
          end
        end
      end
    end
  end
end

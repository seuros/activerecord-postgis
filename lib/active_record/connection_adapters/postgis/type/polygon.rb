# frozen_string_literal: true

require_relative "spatial"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class Polygon < Spatial
          def initialize(srid: 0, has_z: false, has_m: false, geographic: false)
            super(geo_type: "polygon", srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          end

          def type
            :st_polygon
          end
        end
      end
    end
  end
end

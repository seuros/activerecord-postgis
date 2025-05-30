# frozen_string_literal: true

require_relative "spatial"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class MultiPoint < Spatial
          def initialize(srid: 0, has_z: false, has_m: false, geographic: false)
            super(geo_type: "multi_point", srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          end

          def type
            :st_multi_point
          end
        end
      end
    end
  end
end

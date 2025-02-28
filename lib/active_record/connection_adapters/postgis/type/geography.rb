# frozen_string_literal: true

require_relative "spatial"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class Geography < Spatial
          def initialize(srid: 4326, has_z: false, has_m: false)
            super(geo_type: "geography", srid: srid, has_z: has_z, has_m: has_m)
          end

          def type
            :st_geography
          end
        end
      end
    end
  end
end

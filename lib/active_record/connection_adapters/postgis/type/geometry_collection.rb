# frozen_string_literal: true

require_relative "spatial"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module Type
        class GeometryCollection < Spatial
          def initialize(srid: 0, has_z: false, has_m: false, geographic: false)
            super(geo_type: "geometry_collection", srid: srid, has_z: has_z, has_m: has_m, geographic: geographic)
          end

          def type
            :st_geometry_collection
          end
        end
      end
    end
  end
end

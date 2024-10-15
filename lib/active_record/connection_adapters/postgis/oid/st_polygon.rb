# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StPolygon < Spatial
          def type
            :st_polygon
          end
        end
      end
    end
  end
end

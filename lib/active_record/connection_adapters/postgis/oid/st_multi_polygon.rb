# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StMultiPolygon < Spatial
          def type
            :st_multi_polygon
          end
        end
      end
    end
  end
end

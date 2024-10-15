# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StGeometry < Spatial
          def type
            :st_geometry
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StGeometryCollection < Spatial
          def type
            :st_geometrycollection
          end
        end
      end
    end
  end
end

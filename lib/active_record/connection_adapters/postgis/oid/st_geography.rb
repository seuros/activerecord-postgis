# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StGeography < Spatial
          def type
            :st_geography
          end
        end
      end
    end
  end
end

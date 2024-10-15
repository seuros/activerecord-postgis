# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StPoint < Spatial
          def type
            :st_point
          end
        end
      end
    end
  end
end

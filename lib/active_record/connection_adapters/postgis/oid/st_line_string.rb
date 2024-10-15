# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StLineString < Spatial
          def type
            :st_line_string
          end
        end
      end
    end
  end
end

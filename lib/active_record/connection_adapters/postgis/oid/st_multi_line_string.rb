# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StMultiLineString < Spatial
          def type
            :st_multi_line_string
          end
        end
      end
    end
  end
end

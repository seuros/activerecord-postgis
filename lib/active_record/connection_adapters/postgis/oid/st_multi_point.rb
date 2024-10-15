# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
        class StMultiPoint < Spatial
          def type
            :st_multipoint
          end
        end
      end
    end
  end
end

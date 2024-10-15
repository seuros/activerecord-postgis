# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SpatialColumnMethods
        extend ActiveSupport::Concern

        included do
          define_column_methods :st_geography,
                                :st_geometry,
                                :st_geometry_collection,
                                :st_line_string,
                                :st_multi_line_string,
                                :st_multi_point,
                                :st_multi_polygon,
                                :st_point,
                                :st_polygon
        end

        def valid_column_definition_options
          super + %i[geographic srid has_z has_m]
        end
      end
    end
  end
end

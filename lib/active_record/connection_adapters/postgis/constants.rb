# lib/active_record/connection_adapters/postgis/constants.rb

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      SPATIAL_TYPES = %i[
        geometry
        geography
        point
        line_string
        polygon
        multi_point
        multi_line_string
        multi_polygon
        geometry_collection
      ].freeze

      GEOMETRIC_TYPES = %i[
        st_geography
        st_geometry
        st_geometry_collection
        st_line_string
        st_multi_line_string
        st_multi_point
        st_multi_polygon
        st_point
        st_polygon
      ].freeze

      VALID_TYPES = %w[
        point line_string polygon multi_point
        multi_line_string multi_polygon geometry_collection geography
      ].freeze
    end
  end
end

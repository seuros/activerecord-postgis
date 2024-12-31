module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module OID
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
        ]

        SPATIAL_TYPES.each do |type|
          class_name = "St#{type.to_s.camelize}"
          const_set(class_name, Class.new(Spatial) do
            define_method(:type) { :"st_#{type}" }
          end)
        end
      end
    end
  end
end

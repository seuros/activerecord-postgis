# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module ColumnExtensions
        def spatial?
          type.to_s.start_with?("st_") ||
          [ :geography, :geometry, :geometry_collection, :line_string,
           :multi_line_string, :multi_point, :multi_polygon, :polygon ].include?(type.to_sym)
        end

        def geographic?
          sql_type.start_with?("geography") || (spatial? && limit.is_a?(Hash) && limit[:geographic])
        end

        def srid
          if spatial?
            if limit.is_a?(Hash) && limit[:srid]
              limit[:srid]
            elsif sql_type =~ /,(\d+)\)/
              $1.to_i
            else
              geographic? ? 4326 : 0
            end
          else
            nil
          end
        end


        def geometric_type
          if spatial?
            case type.to_sym
            when :st_point then RGeo::Feature::Point
            when :st_line_string then RGeo::Feature::LineString
            when :st_polygon then RGeo::Feature::Polygon
            when :st_multi_point then RGeo::Feature::MultiPoint
            when :st_multi_line_string then RGeo::Feature::MultiLineString
            when :st_multi_polygon then RGeo::Feature::MultiPolygon
            when :st_geometry_collection then RGeo::Feature::GeometryCollection
            when :st_geometry then RGeo::Feature::Geometry
            when :st_geography then RGeo::Feature::Geometry
            # Legacy types
            when :geometry then RGeo::Feature::Geometry
            when :geography then RGeo::Feature::Geometry
            when :line_string then RGeo::Feature::LineString
            when :polygon then RGeo::Feature::Polygon
            when :multi_point then RGeo::Feature::MultiPoint
            when :multi_line_string then RGeo::Feature::MultiLineString
            when :multi_polygon then RGeo::Feature::MultiPolygon
            when :geometry_collection then RGeo::Feature::GeometryCollection
            else RGeo::Feature::Geometry
            end
          else
            nil
          end
        end

        def has_z?
          if spatial?
            if limit.is_a?(Hash) && limit.key?(:has_z)
              limit[:has_z]
            elsif sql_type =~ /\b\w+Z\b|\b\w+ZM\b/
              true
            else
              false
            end
          else
            nil
          end
        end

        def has_m?
          if spatial?
            if limit.is_a?(Hash) && limit.key?(:has_m)
              limit[:has_m]
            elsif sql_type =~ /\b\w+M\b|\b\w+ZM\b/
              true
            else
              false
            end
          else
            nil
          end
        end
      end
    end
  end
end

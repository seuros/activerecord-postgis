# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module SpatialQueries
        extend ActiveSupport::Concern

        class_methods do
          # Safe wrapper for ST_Distance queries
          # Usage: Model.where_st_distance(:column, lon, lat, '<', distance)
          # For geographic calculations (meters), cast to geography
          def where_st_distance(column, lon, lat, operator, distance, srid: 4326, geographic: false)
            if geographic
              where("ST_Distance(#{column}::geography, ST_SetSRID(ST_MakePoint(?, ?), ?)::geography) #{operator} ?", lon, lat, srid, distance)
            else
              where("ST_Distance(#{column}, ST_SetSRID(ST_MakePoint(?, ?), ?)) #{operator} ?", lon, lat, srid, distance)
            end
          end

          # Safe wrapper for ST_DWithin queries
          # Usage: Model.where_st_dwithin(:column, lon, lat, distance)
          # For geographic calculations (meters), cast to geography
          def where_st_dwithin(column, lon, lat, distance, srid: 4326, geographic: false)
            if geographic
              where("ST_DWithin(#{column}::geography, ST_SetSRID(ST_MakePoint(?, ?), ?)::geography, ?)", lon, lat, srid, distance)
            else
              where("ST_DWithin(#{column}, ST_SetSRID(ST_MakePoint(?, ?), ?), ?)", lon, lat, srid, distance)
            end
          end

          # Safe wrapper for ST_Contains with point
          # Usage: Model.where_st_contains(:column, lon, lat)
          def where_st_contains(column, lon, lat, srid: 4326)
            where("ST_Contains(#{column}, ST_SetSRID(ST_MakePoint(?, ?), ?))", lon, lat, srid)
          end

          # Safe wrapper for ST_Within with point
          # Usage: Model.where_st_within_point(:column, lon, lat)
          def where_st_within_point(column, lon, lat, srid: 4326)
            where("ST_Within(ST_SetSRID(ST_MakePoint(?, ?), ?), #{column})", lon, lat, srid)
          end

          # Safe wrapper for ST_Intersects with WKT geometry
          # Usage: Model.where_st_intersects(:column, wkt_string)
          def where_st_intersects(column, wkt, srid: 4326)
            where("ST_Intersects(#{column}, ST_GeomFromText(?, ?))", wkt, srid)
          end

          # Generic safe wrapper for any PostGIS function with a point parameter
          # Usage: Model.where_st_function('ST_Distance', :column, lon, lat, '<', value)
          def where_st_function(function, column, lon, lat, operator = nil, value = nil, srid: 4326)
            if operator && value
              where("#{function}(#{column}, ST_SetSRID(ST_MakePoint(?, ?), ?)) #{operator} ?", lon, lat, srid, value)
            else
              where("#{function}(#{column}, ST_SetSRID(ST_MakePoint(?, ?), ?))", lon, lat, srid)
            end
          end
        end
      end

      # Module to include in models for instance methods
      module SpatialScopes
        extend ActiveSupport::Concern

        included do
          # Define commonly used spatial scopes
          scope :within_distance, ->(column, lon, lat, distance, srid: 4326, geographic: false) {
            where_st_distance(column, lon, lat, "<", distance, srid: srid, geographic: geographic)
          }

          scope :beyond_distance, ->(column, lon, lat, distance, srid: 4326, geographic: false) {
            where_st_distance(column, lon, lat, ">", distance, srid: srid, geographic: geographic)
          }

          scope :near, ->(column, lon, lat, distance, srid: 4326, geographic: false) {
            where_st_dwithin(column, lon, lat, distance, srid: srid, geographic: geographic)
          }

          scope :containing_point, ->(column, lon, lat, srid: 4326) {
            where_st_contains(column, lon, lat, srid: srid)
          }

          scope :intersecting, ->(column, wkt, srid: 4326) {
            where_st_intersects(column, wkt, srid: srid)
          }
        end
      end
    end
  end
end

# Automatically include in ActiveRecord::Base
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(ActiveRecord::ConnectionAdapters::PostGIS::SpatialQueries)
end

# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      module ArelExtensions
        # Extend ActiveRecord::Relation to provide spatial query methods using Arel
        module RelationMethods
          def where_st_distance(column, lon, lat, operator, distance, srid: 4326)
            column_node = arel_table[column]
            point = create_point_node(lon, lat, srid)
            
            case operator
            when '<', :lt
              where(column_node.st_distance(point).lt(distance))
            when '>', :gt
              where(column_node.st_distance(point).gt(distance))
            when '<=', :lteq
              where(column_node.st_distance(point).lteq(distance))
            when '>=', :gteq
              where(column_node.st_distance(point).gteq(distance))
            when '=', :eq
              where(column_node.st_distance(point).eq(distance))
            else
              raise ArgumentError, "Unknown operator: #{operator}"
            end
          end
          
          def where_st_dwithin(column, lon, lat, distance, srid: 4326)
            column_node = arel_table[column]
            point = create_point_node(lon, lat, srid)
            
            # For ST_DWithin, we need to use raw SQL as Arel doesn't have native support
            # But we can still use proper parameter binding
            where("ST_DWithin(#{connection.quote_column_name(column)}, ST_SetSRID(ST_MakePoint(?, ?), ?), ?)", 
                  lon, lat, srid, distance)
          end
          
          def where_st_contains(column, geometry)
            column_node = arel_table[column]
            where(column_node.st_contains(wrap_geometry(geometry)))
          end
          
          def where_st_within(geometry, column)
            column_node = arel_table[column]
            where(column_node.st_within(wrap_geometry(geometry)))
          end
          
          def where_st_intersects(column, geometry)
            column_node = arel_table[column]
            where(column_node.st_intersects(wrap_geometry(geometry)))
          end
          
          private
          
          def create_point_node(lon, lat, srid)
            # Create a point using Arel nodes
            # This will be properly handled by our PostGIS visitor
            point = RGeo::Geos.factory(srid: srid).point(lon, lat)
            Arel.spatial(point)
          end
          
          def wrap_geometry(geometry)
            case geometry
            when RGeo::Feature::Instance
              Arel.spatial(geometry)
            when String
              Arel.spatial(geometry)
            else
              geometry
            end
          end
        end
        
        # Extend Arel to support creating points from coordinates
        module ArelPointExtensions
          def st_make_point(x, y, srid = nil)
            if srid
              Arel::Nodes::NamedFunction.new(
                'ST_SetSRID',
                [
                  Arel::Nodes::NamedFunction.new('ST_MakePoint', [x, y]),
                  Arel::Nodes::SqlLiteral.new(srid.to_s)
                ]
              )
            else
              Arel::Nodes::NamedFunction.new('ST_MakePoint', [x, y])
            end
          end
        end
      end
    end
  end
end

# Extend ActiveRecord::Relation with spatial methods
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(ActiveRecord::ConnectionAdapters::PostGIS::ArelExtensions::RelationMethods)
  
  # Extend Arel module with point creation
  Arel.extend(ActiveRecord::ConnectionAdapters::PostGIS::ArelExtensions::ArelPointExtensions)
end
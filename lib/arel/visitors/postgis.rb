# frozen_string_literal: true

require "rgeo"
require "rgeo/active_record/arel_spatial_queries"

module Arel
  module Nodes
    # Spatial node classes for different PostGIS functions
    class SpatialNode < Binary
      def initialize(left, right = nil)
        super(left, right)
      end
    end

    class SpatialDistance < SpatialNode; end
    class SpatialLength < Unary; end
    class SpatialContains < SpatialNode; end
    class SpatialWithin < SpatialNode; end
    class SpatialIntersects < SpatialNode; end
    class SpatialDWithin < SpatialNode
      attr_reader :distance
      
      def initialize(left, right, distance)
        super(left, right)
        @distance = distance
      end
    end
    class SpatialBuffer < SpatialNode
      def st_area
        SpatialArea.new(self)
      end
    end
    class SpatialTransform < SpatialNode
      def st_area
        SpatialArea.new(self)
      end
    end
    class SpatialArea < Unary; end
    
    # K-Nearest Neighbor distance operator
    class SpatialDistanceOperator < Binary
      def initialize(left, right)
        super
      end
    end

    # Wrapper for spatial values that need special handling
    class SpatialValue < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def st_distance(other)
        SpatialDistance.new(self, other)
      end

      def st_contains(other)
        SpatialContains.new(self, other)
      end

      def st_within(other)
        SpatialWithin.new(self, other)
      end

      def st_intersects(other)
        SpatialIntersects.new(self, other)
      end

      def st_dwithin(other, distance)
        SpatialDWithin.new(self, other, distance)
      end

      def st_buffer(distance)
        SpatialBuffer.new(self, distance)
      end

      def st_transform(srid)
        SpatialTransform.new(self, srid)
      end

      def st_area
        SpatialArea.new(self)
      end
      
      def distance_operator(other)
        SpatialDistanceOperator.new(self, other)
      end
      
      alias :'<->' :distance_operator
    end
  end

  module Attributes
    class Attribute
      def st_distance(other)
        Arel::Nodes::SpatialDistance.new(self, other)
      end

      def st_length
        Arel::Nodes::SpatialLength.new(self)
      end

      def st_contains(other)
        Arel::Nodes::SpatialContains.new(self, other)
      end

      def st_within(other)
        Arel::Nodes::SpatialWithin.new(self, other)
      end

      def st_intersects(other)
        Arel::Nodes::SpatialIntersects.new(self, other)
      end

      def st_dwithin(other, distance)
        Arel::Nodes::SpatialDWithin.new(self, other, distance)
      end

      def st_buffer(distance)
        Arel::Nodes::SpatialBuffer.new(self, distance)
      end

      def st_transform(srid)
        Arel::Nodes::SpatialTransform.new(self, srid)
      end

      def st_area
        Arel::Nodes::SpatialArea.new(self)
      end
      
      def distance_operator(other)
        Arel::Nodes::SpatialDistanceOperator.new(self, other)
      end
      
      alias :'<->' :distance_operator
    end
  end

  # Add Arel.spatial() method
  def self.spatial(value)
    Arel::Nodes::SpatialValue.new(value)
  end

  module Visitors
    class PostGIS < PostgreSQL
      include RGeo::ActiveRecord::SpatialToSql

      def visit_in_spatial_context(node, collector)
        # Use ST_GeomFromEWKT for EWKT geometries
        if node.is_a?(String) && node =~ /SRID=\d*;/
          collector << "ST_GeomFromEWKT(#{quote(node)})"
        else
          super(node, collector) if defined?(super)
        end
      end

      # Visitor methods for spatial nodes
      def visit_Arel_Nodes_SpatialDistance(node, collector)
        collector << "ST_Distance("
        visit(node.left, collector)
        collector << ", "
        visit_spatial_operand(node.right, collector)
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialLength(node, collector)
        collector << "ST_Length("
        visit(node.expr, collector)
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialContains(node, collector)
        collector << "ST_Contains("
        visit(node.left, collector)
        collector << ", "
        visit_spatial_operand(node.right, collector)
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialWithin(node, collector)
        collector << "ST_Within("
        visit(node.left, collector)
        collector << ", "
        visit_spatial_operand(node.right, collector)
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialValue(node, collector)
        visit_spatial_operand(node.value, collector)
      end

      def visit_Arel_Nodes_SpatialIntersects(node, collector)
        collector << "ST_Intersects("
        visit(node.left, collector)
        collector << ", "
        visit_spatial_operand(node.right, collector)
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialDWithin(node, collector)
        collector << "ST_DWithin("
        visit(node.left, collector)
        collector << ", "
        visit_spatial_operand(node.right, collector)
        collector << ", "
        collector << node.distance.to_s
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialBuffer(node, collector)
        collector << "ST_Buffer("
        visit(node.left, collector)
        collector << ", "
        collector << node.right.to_s
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialTransform(node, collector)
        collector << "ST_Transform("
        visit(node.left, collector)
        collector << ", "
        collector << node.right.to_s
        collector << ")"
      end

      def visit_Arel_Nodes_SpatialArea(node, collector)
        collector << "ST_Area("
        visit(node.expr, collector)
        collector << ")"
      end
      
      def visit_Arel_Nodes_SpatialDistanceOperator(node, collector)
        visit(node.left, collector)
        collector << " <-> "
        visit_spatial_operand(node.right, collector)
      end

      private

      def visit_spatial_operand(operand, collector)
        case operand
        when String
          if operand =~ /SRID=\d*;/
            collector << "ST_GeomFromEWKT(#{quote(operand)})"
          else
            collector << "ST_GeomFromText(#{quote(operand)})"
          end
        when RGeo::Feature::Instance
          ewkt = if operand.srid && operand.srid != 0
                   "SRID=#{operand.srid};#{operand.as_text}"
          else
                   operand.as_text
          end
          collector << "ST_GeomFromEWKT(#{quote(ewkt)})"
        when RGeo::Cartesian::BoundingBox
          # Convert bounding box to polygon WKT with SRID if available
          wkt = "POLYGON((#{operand.min_x} #{operand.min_y}, #{operand.max_x} #{operand.min_y}, #{operand.max_x} #{operand.max_y}, #{operand.min_x} #{operand.max_y}, #{operand.min_x} #{operand.min_y}))"
          if operand.respond_to?(:srid) && operand.srid && operand.srid != 0
            ewkt = "SRID=#{operand.srid};#{wkt}"
            collector << "ST_GeomFromEWKT(#{quote(ewkt)})"
          else
            collector << "ST_GeomFromText(#{quote(wkt)})"
          end
        else
          visit(operand, collector)
        end
      end
    end
  end
end

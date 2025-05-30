# frozen_string_literal: true

require "rgeo"
require "rgeo/active_record/arel_spatial_queries"

module RGeo
  module ActiveRecord
    # Extend rgeo-activerecord visitors to use PostGIS specific functionality
    module SpatialToPostGISSql
      include RGeo::ActiveRecord::SpatialToSql

      def visit_in_spatial_context(node, collector)
        # Use ST_GeomFromEWKT for EWKT geometries
        if node.is_a?(String) && node =~ /SRID=\d*;/
          collector << "ST_GeomFromEWKT(#{quote(node)})"
        else
          super(node, collector) if defined?(super)
        end
      end
    end
  end
end

module Arel
  module Visitors
    class PostGIS < PostgreSQL
      include RGeo::ActiveRecord::SpatialToPostGISSql
    end
  end
end

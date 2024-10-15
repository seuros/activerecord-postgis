# frozen_string_literal: true

# Get the path to the ActiveRecord gem
activerecord_path = Gem::Specification.find_by_name("activerecord").gem_dir

# Construct the full path to the Arel visitors PostgreSQL file
arel_postgresql_path = File.join(activerecord_path, "lib/arel/visitors/postgresql")

# Require the Arel visitors PostgreSQL file
require arel_postgresql_path

# Patch the Arel::Visitors::PostgreSQL class
module Arel
  module Visitors
    class PostgreSQL
      class_eval do
        # Redefine or patch the visit_in_spatial_context method
        def visit_in_spatial_context(node, collector)
          # Use ST_GeomFromEWKT for EWKT geometries
          if node.is_a?(String) && node =~ /SRID=[\d+]{0,};/
            collector << "#{st_func('ST_GeomFromEWKT')}(#{quote(node)})"
          else
            super(node, collector)
          end
        end
      end
    end
  end
end

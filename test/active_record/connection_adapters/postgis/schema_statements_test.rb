# frozen_string_literal: true

require_relative "../../../test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SchemaStatementsTest < ActiveSupport::TestCase
        def test_initialize_type_map
          SpatialModel.with_connection do |connection|
            connection.connect!
            initialized_types = connection.send(:type_map).keys

            # PostGIS types must be initialized first, so
            # ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#load_additional_types can use them.
            # https://github.com/rails/rails/blob/8d57cb39a88787bb6cfb7e1c481556ef6d8ede7a/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L593

            # In our gem architecture, we register geometry and geography types with proper handlers
            assert_includes initialized_types, "geometry"
            assert_includes initialized_types, "geography"
          end
        end
      end
    end
  end
end

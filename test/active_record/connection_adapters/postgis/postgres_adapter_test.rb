# frozen_string_literal: true

require "test_helper"
require "active_record/connection_adapters/postgresql_adapter"

class PostgresAdapterTest < ActiveSupport::TestCase
  test "should list all registered types in PostgreSQL adapter" do
    registered_types = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.native_database_types

    # Ensure that we retrieved some types
    assert registered_types.any?, "No types found in the PostgreSQL adapter"

    expected_types = %w[st_geography st_geometry st_geometry_collection st_line_string st_multi_line_string
                        st_multi_point st_multi_polygon st_point st_polygon]

    expected_types.each do |expected_type|
      assert_includes registered_types.keys, expected_type.to_sym, "Expected type #{expected_type} not found"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to retrieve types: #{e.message}"
    assert false, "Exception occurred: #{e.message}"
  end
end

# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SetupTest < ActiveSupport::TestCase
        def test_ignore_tables
          expect_to_ignore = PostGIS::POSTGIS_SYSTEM_TABLES
          # Check that our PostGIS tables are in the ignore list
          ignored_tables = PostGIS.schema_ignored_tables
          expect_to_ignore.each do |table|
            assert_includes ignored_tables, table, "#{table} should be ignored in schema dumps"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class DatabaseStatementsTest < ActiveSupport::TestCase
        setup do
          # Ensure PostGIS extension is enabled before running tests
          ActiveRecord::Base.connection.enable_extension("postgis") unless ActiveRecord::Base.connection.extension_enabled?("postgis")
          # Ensure PostGIS support is initialized
          ActiveRecord::ConnectionAdapters::PostGIS.initialize!
        end

        def test_truncate_tables_leaves_spatial_ref_sys_intact
          initial_count = spatial_ref_sys_count

          assert initial_count.positive?, "spatial_ref_sys count should not be zero"

          ActiveRecord::Tasks::DatabaseTasks.send(:truncate_tables, :test)

          assert_equal initial_count, spatial_ref_sys_count, "spatial_ref_sys should not be truncated"
        end

        private

        def spatial_ref_sys_count
          ActiveRecord::Base.with_connection do |connection|
            connection.select_value("SELECT COUNT(*) FROM spatial_ref_sys").to_i
          end
        end
      end
    end
  end
end

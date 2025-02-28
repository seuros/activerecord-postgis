# frozen_string_literal: true

require "test_helper"

class SqliteIsolationTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    # Configure SQLite connection
    @sqlite_config = {
      adapter: "sqlite3",
      database: ":memory:"
    }

    # Create a separate SQLite connection
    @sqlite_connection = ActiveRecord::Base.establish_connection(@sqlite_config)
    @sqlite_connection = ActiveRecord::Base.connection
  end

  teardown do
    # Clean up SQLite connection
    @sqlite_connection&.disconnect!
    # Restore original PostgreSQL connection
    ActiveRecord::Base.establish_connection(:primary)
  end

  test "sqlite adapter is not affected by postgis gem" do
    # Verify we're using SQLite
    assert_equal "SQLite", @sqlite_connection.adapter_name

    # Create a simple table with standard column types
    @sqlite_connection.create_table :test_sqlite_table, force: true do |t|
      t.string :name
      t.integer :age
      t.float :height
      t.decimal :weight, precision: 5, scale: 2
      t.boolean :active
      t.datetime :created_at
      t.text :description
    end

    # Verify table was created successfully
    assert @sqlite_connection.table_exists?(:test_sqlite_table)

    # Verify columns have correct types
    columns = @sqlite_connection.columns(:test_sqlite_table)
    name_col = columns.find { |c| c.name == "name" }
    age_col = columns.find { |c| c.name == "age" }

    assert_equal "varchar", name_col.sql_type.downcase
    assert_equal "integer", age_col.sql_type.downcase

    # Verify we can insert and query data
    @sqlite_connection.execute("INSERT INTO test_sqlite_table (name, age) VALUES ('Test', 25)")
    result = @sqlite_connection.select_one("SELECT name, age FROM test_sqlite_table WHERE name = 'Test'")

    assert_equal "Test", result["name"]
    assert_equal 25, result["age"]
  ensure
    @sqlite_connection.drop_table :test_sqlite_table, if_exists: true
  end

  test "sqlite does not have postgis spatial types" do
    # Verify SQLite adapter doesn't have PostGIS types
    assert_equal "SQLite", @sqlite_connection.adapter_name

    # Verify PostGIS spatial types are not available
    native_types = @sqlite_connection.native_database_types

    # These should not exist in SQLite
    assert_not native_types.key?(:st_point)
    assert_not native_types.key?(:st_geometry)
    assert_not native_types.key?(:st_geography)
    assert_not native_types.key?(:geometry)
    assert_not native_types.key?(:geography)
  end

  test "sqlite table definition does not have spatial column methods" do
    # Verify SQLite table definition doesn't have spatial methods
    error_raised = false

    begin
      @sqlite_connection.create_table :test_methods_table, force: true do |t|
        # These should work fine - standard column types
        t.string :name
        t.integer :id_number

        # This spatial method should not be available in SQLite
        t.st_point :location
      end
    rescue NoMethodError => e
      error_raised = true
      assert_match(/st_point/, e.message, "Expected NoMethodError for st_point method")
    rescue StandardError => e
      # If a different error occurs (like SQL error), that's also fine
      # since it means the method tried to execute but failed due to SQLite limitations
      error_raised = true
      assert e.message.present?, "Expected some error when trying to use PostGIS types in SQLite"
    ensure
      @sqlite_connection.drop_table :test_methods_table, if_exists: true if @sqlite_connection.table_exists?(:test_methods_table)
    end

    assert error_raised, "Expected an error when trying to use PostGIS spatial methods in SQLite"
  end
end

# frozen_string_literal: true

require "test_helper"

# Testing the Quantum Database - where PostgreSQL meets quantum mechanics! 🚀⚛️
class QuantumDatabaseTest < ActiveSupport::TestCase
  def test_quantum_observer_exists_in_parallel_dimension
    # Test that QuantumObserver connects to the parallel PostgreSQL dimension
    assert_equal "active_record_quantum_test", QuantumObserver.connection_db_config.database
  end

  def test_quantum_state_collapse_on_observation
    # Test creating a quantum observer - their state collapses when observed!
    observer = QuantumObserver.create!(
      name: "Schrödinger's Developer",
      email: "quantum@multiverse.com",
      coordinates: "(42.0,3.14)"  # Classical coordinates (collapsed from quantum superposition)
    )

    assert observer.persisted?, "Quantum observer failed to materialize in this dimension!"
    assert_equal "Schrödinger's Developer", observer.name
    assert_equal "quantum@multiverse.com", observer.email
  end

  def test_classical_physics_only_in_parallel_dimension
    # Verify that PostGIS quantum spatial types don't work in the classical dimension
    # This dimension only supports Newtonian physics (PostgreSQL native point type)
    connection = QuantumObserver.connection

    # The spatial methods are available (since PostGIS gem is loaded),
    # but they should fail when trying to use PostGIS types in a non-PostGIS database
    begin
      connection.create_table :test_quantum_leak, force: true do |t|
        t.st_point :quantum_location  # This should fail in non-PostGIS database
      end

      # If we get here, the table was created successfully
      # This means PostGIS is actually enabled in this database
      # In that case, let's verify the table has the expected structure
      columns = connection.columns(:test_quantum_leak)
      location_col = columns.find { |c| c.name == "quantum_location" }

      # If PostGIS is enabled, we expect geometry type
      if location_col.sql_type.include?("geometry")
        # PostGIS is enabled - this is unexpected for the quantum dimension
        flunk "Quantum dimension unexpectedly has PostGIS enabled! Expected plain PostgreSQL."
      else
        # Non-PostGIS type - this would be unexpected since st_point should create geometry
        flunk "Unexpected column type: #{location_col.sql_type}"
      end

    rescue StandardError => e
      # Good! We expect some kind of error when using PostGIS types without PostGIS
      assert e.message.present?, "Expected an error when using PostGIS types without PostGIS extension"
    ensure
      # Clean up the table, but handle transaction errors
      begin
        connection.drop_table :test_quantum_leak, if_exists: true
      rescue ActiveRecord::StatementInvalid
        # If transaction is aborted, we can't clean up in this transaction
        # The table creation failed anyway, so there's nothing to clean up
      end
    end
  end
end

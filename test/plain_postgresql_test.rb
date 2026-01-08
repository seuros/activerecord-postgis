# frozen_string_literal: true

require "test_helper"

# Testing the Quantum Database - where PostgreSQL meets quantum mechanics! 🚀⚛️
class QuantumDatabaseTest < ActiveSupport::TestCase
  def test_quantum_observer_exists_in_parallel_dimension
    # Test that QuantumObserver connects to the parallel PostgreSQL dimension
    assert_equal "active_record_quantum_test", QuantumObserver.connection_db_config.database
  end

  def test_postgis_not_enabled_in_quantum_dimension
    # Verify that PostGIS extension is NOT enabled in the secondary database
    connection = QuantumObserver.connection
    refute connection.extension_enabled?("postgis"),
      "PostGIS should NOT be enabled in the quantum dimension (secondary database)"
  end

  def test_quantum_state_collapse_on_observation
    # Test creating a quantum observer - their state collapses when observed!
    observer = QuantumObserver.create!(
      name: "Schrödinger's Developer",
      email: "quantum#{SecureRandom.hex(4)}@multiverse.com",
      coordinates: "(42.0,3.14)"  # Classical coordinates (collapsed from quantum superposition)
    )

    assert observer.persisted?, "Quantum observer failed to materialize in this dimension!"
    assert_equal "Schrödinger's Developer", observer.name
  end

  def test_spatial_types_fail_gracefully_without_postgis
    # Verify that PostGIS spatial types fail gracefully in non-PostGIS database
    # The gem detects PostGIS is not available and skips type registration
    # But column methods still exist, so SQL execution will fail with type error
    connection = QuantumObserver.connection

    error = assert_raises(ActiveRecord::StatementInvalid) do
      connection.create_table :test_quantum_leak, force: true do |t|
        t.st_point :quantum_location  # This should fail - geometry type doesn't exist
      end
    end

    # Expect PostgreSQL error about unknown type
    assert_match(/type.*geometry.*does not exist|type "geometry" does not exist/i, error.message)
  ensure
    begin
      connection.drop_table :test_quantum_leak, if_exists: true
    rescue ActiveRecord::StatementInvalid
      # Table may not exist or transaction may be aborted
    end
  end
end

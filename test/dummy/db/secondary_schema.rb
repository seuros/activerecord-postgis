# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_25_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "quantum_observers", comment: "Parallel dimension entities using classical PostgreSQL physics only. \n         No PostGIS quantum spatial types allowed in this reality!\n         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord", force: :cascade do |t|
    t.string "name", null: false, comment: "Quantum state identifier - collapses upon observation"
    t.string "email", null: false, comment: "Quantum entangled communication channel across dimensions"
    t.point "coordinates", comment: "Classical Newtonian coordinates (no quantum superposition here!)"
    t.datetime "created_at", null: false, comment: "Timestamp of last quantum measurement collapse"
    t.datetime "updated_at", null: false, comment: "Timestamp of last quantum measurement collapse"
    t.index ["email"], name: "index_quantum_observers_on_email", unique: true
  end
end

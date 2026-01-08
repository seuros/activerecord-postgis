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

ActiveRecord::Schema[8.1].define(version: 2025_01_01_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "uuid-ossp"

  create_table "buildings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_point "entrance", srid: 32633
    t.integer "floors"
    t.st_polygon "footprint", srid: 32633
    t.st_point "location_ca", srid: 2227
    t.st_point "location_mercator", srid: 3857
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "cities", force: :cascade do |t|
    t.st_polygon "boundaries", geographic: true
    t.st_point "center", geographic: true
    t.datetime "created_at", null: false
    t.st_multi_polygon "districts", geographic: true
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "foos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invalid_attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "land_masses_with_politicians", comment: "Geographic territories inhabited by political entities and their associated complications.\n         PostGIS spatial precision tracks land boundaries with mathematical accuracy,\n         while political boundaries remain perpetually questionable.\n         🌍🎭 Warning: May contain traces of democracy, corruption, and campaign promises.\n         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord - Political Geography Edition", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "When this political arrangement was last stable"
    t.st_point "location", comment: "Precise PostGIS coordinates (more accurate than their political promises)"
    t.string "name", comment: "Official designation of the political experiment"
    t.datetime "updated_at", null: false, comment: "When this political arrangement was last stable"
  end

  create_table "locations", force: :cascade do |t|
    t.st_polygon "boundary"
    t.datetime "created_at", null: false
    t.string "name"
    t.st_point "position"
    t.st_line_string "route"
    t.datetime "updated_at", null: false
  end

  create_table "mixed_spatial", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_line_string "geog_line", geographic: true
    t.st_point "geog_point", comment: "WGS84 geography point", geographic: true
    t.st_polygon "geog_poly", geographic: true
    t.st_line_string "geom_line", srid: 3857
    t.st_point "geom_point", comment: "WGS84 geometry point", srid: 4326
    t.st_polygon "geom_poly", srid: 2154
    t.string "name"
    t.st_geometry "shape", comment: "Generic geometry column"
    t.datetime "updated_at", null: false
  end

  create_table "parks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_multi_point "entrances"
    t.st_geometry_collection "features"
    t.string "name"
    t.st_multi_line_string "trails"
    t.datetime "updated_at", null: false
    t.st_multi_polygon "zones"
  end

  create_table "quantum_cats", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Quantum felines existing in superposition states until observed.\n         Each cat exists simultaneously in all possible states within the PostGIS quantum spatial dimension.\n         🚀⚛️ Part of the first Quantum Opensource Database for ActiveRecord - PostGIS Edition", force: :cascade do |t|
    t.datetime "created_at", null: false, comment: "When the cat's state was last observed"
    t.string "name", comment: "Cat identifier - observing this field collapses the quantum state"
    t.datetime "updated_at", null: false, comment: "When the cat's state was last observed"
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "distance"
    t.string "name"
    t.st_line_string "path_3d", srid: 4326, has_z: true
    t.st_line_string "path_4d", srid: 4326, has_z: true, has_m: true
    t.st_line_string "path_measured", srid: 4326, has_m: true
    t.datetime "updated_at", null: false
    t.st_multi_point "waypoints_3d", srid: 4326, has_z: true
  end

  create_table "spatial_foos", force: :cascade do |t|
    t.st_point "cart_point", srid: 3509
    t.datetime "created_at", null: false
    t.bigint "foo_id", null: false
    t.st_point "geo_point", geographic: true
    t.datetime "updated_at", null: false
    t.index ["foo_id"], name: "index_spatial_foos_on_foo_id"
  end

  create_table "test_native_pg_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.st_point "gis_point"
    t.st_polygon "gis_polygon"
    t.string "name"
    t.point "pg_point"
    t.st_polygon "pg_polygon"
    t.datetime "updated_at", null: false
  end

  create_table "test_spatial_methods", force: :cascade do |t|
    t.st_polygon "area"
    t.st_multi_polygon "areas"
    t.datetime "created_at", null: false
    t.st_geometry_collection "features"
    t.st_point "location"
    t.string "name"
    t.st_line_string "path"
    t.st_multi_line_string "paths"
    t.st_multi_point "points"
    t.st_geography "region"
    t.st_geometry "shape"
    t.datetime "updated_at", null: false
  end

  create_table "test_spatial_subtypes", force: :cascade do |t|
    t.st_polygon "area"
    t.datetime "created_at", null: false
    t.st_point "location"
    t.string "name"
    t.st_line_string "path"
    t.datetime "updated_at", null: false
  end

  create_table "test_st_aliases", force: :cascade do |t|
    t.st_polygon "area"
    t.st_multi_polygon "areas"
    t.datetime "created_at", null: false
    t.st_geometry_collection "features"
    t.st_point "location"
    t.string "name"
    t.st_line_string "path"
    t.st_multi_line_string "paths"
    t.st_multi_point "points"
    t.st_geography "region"
    t.st_geometry "shape"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "spatial_foos", "foos"
end

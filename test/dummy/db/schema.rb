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

ActiveRecord::Schema[8.0].define(version: 2025_01_01_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"
  enable_extension "uuid-ossp"

  create_table "buildings", force: :cascade do |t|
    t.string "name"
    t.integer "floors"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_polygon "footprint", srid: 32633
    t.st_point "entrance", srid: 32633
    t.st_point "location_mercator", srid: 3857
    t.st_point "location_ca", srid: 2227
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_point "center"
    t.st_polygon "boundaries"
    t.st_multi_polygon "districts"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.point "location"
    t.datetime "created_at", null: false
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

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_point "position"
    t.st_line_string "route"
    t.st_polygon "boundary"
  end

  create_table "mixed_spatial", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_geometry "shape", comment: "Generic geometry column"
    t.st_point "geom_point", comment: "WGS84 geometry point", srid: 4326
    t.st_line_string "geom_line", srid: 3857
    t.st_polygon "geom_poly", srid: 2154
    t.st_point "geog_point", comment: "WGS84 geography point"
    t.st_line_string "geog_line"
    t.st_polygon "geog_poly"
  end

  create_table "parks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_multi_point "entrances"
    t.st_multi_line_string "trails"
    t.st_multi_polygon "zones"
    t.st_geometry_collection "features"
  end

  create_table "routes", force: :cascade do |t|
    t.string "name"
    t.float "distance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.st_line_string "path_3d", srid: 4326, has_z: true
    t.st_multi_point "waypoints_3d", srid: 4326, has_z: true
    t.st_line_string "path_measured", srid: 4326, has_m: true
    t.st_line_string "path_4d", srid: 4326, has_z: true, has_m: true
  end

  create_table "spatial_foos", force: :cascade do |t|
    t.bigint "foo_id", null: false
    t.st_geography "geo_point"
    t.st_point "cart_point", srid: 3509
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "foo_id" ], name: "index_spatial_foos_on_foo_id"
  end

  create_table "test_native_pg_types", force: :cascade do |t|
    t.string "name"
    t.point "pg_point"
    t.st_polygon "pg_polygon"
    t.st_point "gis_point"
    t.st_polygon "gis_polygon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_spatial_methods", force: :cascade do |t|
    t.string "name"
    t.st_point "location"
    t.st_line_string "path"
    t.st_polygon "area"
    t.st_multi_point "points"
    t.st_multi_line_string "paths"
    t.st_multi_polygon "areas"
    t.st_geometry_collection "features"
    t.st_geometry "shape"
    t.st_geography "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_spatial_subtypes", force: :cascade do |t|
    t.string "name"
    t.st_point "location"
    t.st_line_string "path"
    t.st_polygon "area"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_st_aliases", force: :cascade do |t|
    t.string "name"
    t.st_point "location"
    t.st_line_string "path"
    t.st_polygon "area"
    t.st_multi_point "points"
    t.st_multi_line_string "paths"
    t.st_multi_polygon "areas"
    t.st_geometry_collection "features"
    t.st_geometry "shape"
    t.st_geography "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "spatial_foos", "foos"
end

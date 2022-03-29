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

ActiveRecord::Schema.define(version: 2022_02_27_103029) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "exercises", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "user_id"
    t.datetime "start_time", precision: 6, null: false
    t.integer "exercise_type", null: false
    t.integer "duration", null: false
    t.float "burned_calorie", null: false
    t.float "min_heart_rate", null: false
    t.float "mean_heart_rate", null: false
    t.float "max_heart_rate", null: false
    t.datetime "end_time", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_exercises_on_user_id"
    t.index ["uuid"], name: "index_exercises_on_uuid", unique: true
  end

  create_table "personal_files", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "user_id"
    t.string "type", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_personal_files_on_user_id"
    t.index ["uuid"], name: "index_personal_files_on_uuid", unique: true
  end

  create_table "sleep_sessions", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "user_id"
    t.datetime "start_time", precision: 6, null: false
    t.integer "mental_recovery", null: false
    t.integer "physical_recovery", null: false
    t.integer "movement_duration", null: false
    t.integer "efficiency", null: false
    t.integer "score", null: false
    t.integer "cycle", null: false
    t.integer "duration", null: false
    t.datetime "end_time", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_sleep_sessions_on_user_id"
    t.index ["uuid"], name: "index_sleep_sessions_on_uuid", unique: true
  end

  create_table "sleep_stages", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "sleep_session_id"
    t.datetime "start_time", precision: 6, null: false
    t.integer "stage", null: false
    t.datetime "end_time", precision: 6, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["sleep_session_id"], name: "index_sleep_stages_on_sleep_session_id"
    t.index ["uuid"], name: "index_sleep_stages_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "email", null: false
    t.integer "age", null: false
    t.string "password_digest"
    t.boolean "terms_and_conditions", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  create_table "values", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "user_id"
    t.string "type", null: false
    t.datetime "start_time", precision: 6, null: false
    t.float "min", null: false
    t.float "mean", null: false
    t.float "max", null: false
    t.datetime "end_time", precision: 6, null: false
    t.jsonb "payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_values_on_user_id"
    t.index ["uuid"], name: "index_values_on_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "exercises", "users"
  add_foreign_key "personal_files", "users"
  add_foreign_key "sleep_sessions", "users"
  add_foreign_key "sleep_stages", "sleep_sessions"
  add_foreign_key "values", "users"
end

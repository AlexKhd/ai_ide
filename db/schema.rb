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

ActiveRecord::Schema[8.0].define(version: 2026_05_31_211203) do
  create_table "ai_connections", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false, null: false
    t.bigint "model_id"
  end

  create_table "ai_models", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.integer "context_length"
    t.json "input_modalities"
    t.json "output_modalities"
    t.boolean "supports_tools", default: false
    t.boolean "supports_reasoning", default: false
    t.decimal "prompt_price", precision: 12, scale: 8
    t.decimal "completion_price", precision: 12, scale: 8
    t.json "architecture"
    t.json "raw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["active"], name: "index_ai_models_on_active"
    t.index ["external_id"], name: "index_ai_models_on_external_id", unique: true
    t.index ["provider"], name: "index_ai_models_on_provider"
  end

  create_table "app_folders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "path", null: false
    t.text "description"
    t.string "language"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "path"], name: "index_app_folders_on_user_id_and_path", unique: true
    t.index ["user_id"], name: "index_app_folders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "nickname"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "user", null: false
    t.string "working_directory"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "ai_connections", "ai_models", column: "model_id"
  add_foreign_key "app_folders", "users"
  add_foreign_key "sessions", "users"
end

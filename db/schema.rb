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

ActiveRecord::Schema[8.0].define(version: 2026_06_27_095512) do
  create_table "ai_connections", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false, null: false
    t.bigint "model_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.integer "ai_session_id", null: false
    t.string "role", null: false
    t.text "content"
    t.string "name"
    t.string "tool_call_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_session_id", "created_at"], name: "index_ai_messages_on_ai_session_id_and_created_at"
    t.index ["ai_session_id"], name: "index_ai_messages_on_ai_session_id"
    t.index ["role"], name: "index_ai_messages_on_role"
    t.index ["tool_call_id"], name: "index_ai_messages_on_tool_call_id"
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

  create_table "ai_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "ai_model_id", null: false
    t.integer "ai_connection_id"
    t.string "title"
    t.text "system_prompt"
    t.float "temperature"
    t.integer "max_tokens"
    t.boolean "active", default: true, null: false
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_connection_id"], name: "index_ai_sessions_on_ai_connection_id"
    t.index ["ai_model_id"], name: "index_ai_sessions_on_ai_model_id"
    t.index ["user_id", "active"], name: "index_ai_sessions_on_user_id_and_active"
    t.index ["user_id"], name: "index_ai_sessions_on_user_id"
  end

  create_table "ai_tool_calls", force: :cascade do |t|
    t.integer "ai_message_id", null: false
    t.integer "mcp_tool_id", null: false
    t.string "status"
    t.json "input"
    t.json "output"
    t.text "error"
    t.integer "duration_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_message_id", "created_at"], name: "index_ai_tool_calls_on_ai_message_id_and_created_at"
    t.index ["ai_message_id"], name: "index_ai_tool_calls_on_ai_message_id"
    t.index ["mcp_tool_id"], name: "index_ai_tool_calls_on_mcp_tool_id"
    t.index ["status"], name: "index_ai_tool_calls_on_status"
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

  create_table "mcp_tools", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.json "schema"
    t.boolean "enabled", default: true, null: false
    t.integer "timeout_ms"
    t.string "handler_type"
    t.json "handler_config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_mcp_tools_on_enabled"
    t.index ["name"], name: "index_mcp_tools_on_name", unique: true
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
  add_foreign_key "ai_messages", "ai_sessions"
  add_foreign_key "ai_sessions", "ai_connections"
  add_foreign_key "ai_sessions", "ai_models"
  add_foreign_key "ai_sessions", "users"
  add_foreign_key "ai_tool_calls", "ai_messages"
  add_foreign_key "ai_tool_calls", "mcp_tools"
  add_foreign_key "app_folders", "users"
  add_foreign_key "sessions", "users"
end

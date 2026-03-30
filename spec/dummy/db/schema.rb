# SQLite-compatible schema for the spec/dummy test app.
# Production apps use the gem's db/migrate/ files (PostgreSQL/jsonb).

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000003) do
  create_table "omni_event_notifiers" do |t|
    t.string  "name",                null: false
    t.string  "token",               null: false
    t.boolean "check_ip",            null: false, default: false
    t.text    "allowed_ips",         null: false, default: "[]"
    t.string  "secret_key"
    t.integer "timestamp_tolerance", null: false, default: 300
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], unique: true
  end

  create_table "omni_event_webhook_events" do |t|
    t.bigint  "webhook_notifier_id", null: false
    t.text    "headers",  null: false, default: "{}"
    t.text    "payload",  null: false, default: "{}"
    t.string  "status",   null: false, default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["webhook_notifier_id"]
    t.index ["status"]
  end

  create_table "omni_event_logs" do |t|
    t.string  "loggable_type"
    t.bigint  "loggable_id"
    t.string  "action_type", null: false, default: "system_info"
    t.text    "content"
    t.text    "metadata", null: false, default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"]
    t.index ["action_type"]
  end

  # ActiveStorage (required by OmniEvent::Log#has_one_attached)
  create_table "active_storage_blobs" do |t|
    t.string   "key",          null: false
    t.string   "filename",     null: false
    t.string   "content_type"
    t.text     "metadata"
    t.string   "service_name", null: false
    t.bigint   "byte_size",    null: false
    t.string   "checksum"
    t.datetime "created_at",   null: false
    t.index ["key"], unique: true
  end

  create_table "active_storage_attachments" do |t|
    t.string  "name",        null: false
    t.string  "record_type", null: false
    t.bigint  "record_id",   null: false
    t.bigint  "blob_id",     null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"]
    t.index ["record_type", "record_id", "name", "blob_id"],
            name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_variant_records" do |t|
    t.bigint "blob_id",          null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"],
            name: "index_active_storage_variant_records_uniqueness", unique: true
  end
end

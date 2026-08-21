# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "slug" ], name: "index_tenants_on_slug", unique: true, where: "slug IS NOT NULL AND archived_at IS NULL"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.string "title", null: false
    t.integer "position", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "tenant_id", "position" ], name: "index_projects_on_tenant_id_and_position", unique: true
    t.index [ "tenant_id" ], name: "index_projects_on_tenant_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name"
    t.boolean "done", default: false, null: false
    t.datetime "confirmed_at"
    t.integer "confirmed_by_id"
    t.text "notes"
    t.decimal "estimate", precision: 6, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "project_id" ], name: "index_tasks_on_project_id"
    t.check_constraint "(confirmed_by_id IS NULL AND confirmed_at IS NULL) OR (confirmed_by_id IS NOT NULL AND confirmed_at IS NOT NULL)", name: "tasks_confirmation_pair"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.integer "commentable_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "commentable_type", "commentable_id" ], name: "index_comments_on_commentable"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "type", null: false
    t.string "plate"
    t.integer "wheels", default: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "plate" ], name: "index_vehicles_on_plate", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_users_on_email", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
  end
end

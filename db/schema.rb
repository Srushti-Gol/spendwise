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

ActiveRecord::Schema[8.1].define(version: 2024_01_01_000014) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "approval_rules", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "department"
    t.decimal "min_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "max_amount", precision: 15, scale: 2
    t.string "approver_role", null: false
    t.integer "level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "department", "level"], name: "index_approval_rules_on_tenant_id_and_department_and_level"
    t.index ["tenant_id"], name: "index_approval_rules_on_tenant_id"
  end

  create_table "approval_steps", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "requisition_id", null: false
    t.bigint "approver_id", null: false
    t.integer "level", null: false
    t.string "status", default: "pending", null: false
    t.text "comment"
    t.datetime "decided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_approval_steps_on_approver_id"
    t.index ["requisition_id", "level"], name: "index_approval_steps_on_requisition_id_and_level"
    t.index ["requisition_id"], name: "index_approval_steps_on_requisition_id"
    t.index ["tenant_id", "approver_id", "status"], name: "idx_approval_steps_inbox"
    t.index ["tenant_id", "status"], name: "idx_approval_steps_pending", where: "((status)::text = 'pending'::text)"
    t.index ["tenant_id"], name: "index_approval_steps_on_tenant_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.string "auditable_type"
    t.bigint "auditable_id"
    t.jsonb "changes_data", default: {}
    t.jsonb "metadata", default: {}
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "auditable_type", "auditable_id"], name: "idx_audit_logs_auditable"
    t.index ["tenant_id", "created_at"], name: "index_audit_logs_on_tenant_id_and_created_at"
    t.index ["tenant_id", "user_id", "created_at"], name: "idx_audit_logs_user_timeline"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "goods_receipt_items", force: :cascade do |t|
    t.bigint "goods_receipt_id", null: false
    t.bigint "purchase_order_item_id", null: false
    t.decimal "quantity_received", precision: 15, scale: 4, null: false
    t.string "condition", default: "good"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["goods_receipt_id"], name: "index_goods_receipt_items_on_goods_receipt_id"
    t.index ["purchase_order_item_id"], name: "index_goods_receipt_items_on_purchase_order_item_id"
  end

  create_table "goods_receipts", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "purchase_order_id", null: false
    t.bigint "received_by_id", null: false
    t.date "received_at", null: false
    t.text "notes"
    t.string "delivery_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_order_id"], name: "index_goods_receipts_on_purchase_order_id"
    t.index ["received_by_id"], name: "index_goods_receipts_on_received_by_id"
    t.index ["tenant_id", "purchase_order_id"], name: "index_goods_receipts_on_tenant_id_and_purchase_order_id"
    t.index ["tenant_id"], name: "index_goods_receipts_on_tenant_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.decimal "quantity", precision: 15, scale: 4
    t.decimal "unit_price", precision: 15, scale: 2
    t.decimal "total_price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "purchase_order_id"
    t.bigint "created_by_id"
    t.string "vendor", null: false
    t.string "invoice_number"
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.string "currency", default: "USD"
    t.date "invoice_date"
    t.string "status", default: "pending", null: false
    t.string "pdf_url"
    t.jsonb "extracted_data", default: {}
    t.jsonb "match_result", default: {}
    t.boolean "price_match"
    t.boolean "quantity_match"
    t.boolean "vendor_match"
    t.decimal "price_variance", precision: 10, scale: 6
    t.decimal "quantity_variance", precision: 10, scale: 6
    t.boolean "is_duplicate", default: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invoices_on_created_by_id"
    t.index ["extracted_data"], name: "index_invoices_on_extracted_data", using: :gin
    t.index ["purchase_order_id"], name: "index_invoices_on_purchase_order_id"
    t.index ["tenant_id", "invoice_number"], name: "idx_invoices_unique_number", unique: true, where: "(invoice_number IS NOT NULL)"
    t.index ["tenant_id", "purchase_order_id"], name: "index_invoices_on_tenant_id_and_purchase_order_id"
    t.index ["tenant_id", "status"], name: "index_invoices_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
    t.index ["vendor"], name: "idx_invoices_vendor_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "purchase_order_items", force: :cascade do |t|
    t.bigint "purchase_order_id", null: false
    t.string "description", null: false
    t.decimal "quantity", precision: 15, scale: 4, null: false
    t.decimal "unit_price", precision: 15, scale: 2, null: false
    t.decimal "total_price", precision: 15, scale: 2, null: false
    t.decimal "received_quantity", precision: 15, scale: 4, default: "0.0"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_order_id"], name: "index_purchase_order_items_on_purchase_order_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "requisition_id"
    t.bigint "created_by_id"
    t.string "vendor", null: false
    t.string "vendor_email"
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.string "status", default: "draft", null: false
    t.decimal "price_tolerance", precision: 5, scale: 4, default: "0.05"
    t.decimal "quantity_tolerance", precision: 5, scale: 4, default: "0.02"
    t.date "expected_delivery_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_purchase_orders_on_created_by_id"
    t.index ["requisition_id"], name: "index_purchase_orders_on_requisition_id"
    t.index ["tenant_id", "status"], name: "index_purchase_orders_on_tenant_id_and_status"
    t.index ["tenant_id", "vendor"], name: "index_purchase_orders_on_tenant_id_and_vendor"
    t.index ["tenant_id"], name: "index_purchase_orders_on_tenant_id"
    t.index ["vendor"], name: "idx_purchase_orders_vendor_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "requisition_items", force: :cascade do |t|
    t.bigint "requisition_id", null: false
    t.string "description", null: false
    t.decimal "quantity", precision: 15, scale: 4, null: false
    t.decimal "unit_price", precision: 15, scale: 2, null: false
    t.decimal "total_price", precision: 15, scale: 2, null: false
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requisition_id"], name: "index_requisition_items_on_requisition_id"
  end

  create_table "requisitions", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "requester_id", null: false
    t.bigint "current_approver_id"
    t.string "title", null: false
    t.text "description"
    t.string "department", null: false
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.string "status", default: "draft", null: false
    t.boolean "self_approval_blocked", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_approver_id"], name: "index_requisitions_on_current_approver_id"
    t.index ["requester_id"], name: "index_requisitions_on_requester_id"
    t.index ["tenant_id", "current_approver_id", "status"], name: "idx_requisitions_approval_inbox"
    t.index ["tenant_id", "requester_id"], name: "index_requisitions_on_tenant_id_and_requester_id"
    t.index ["tenant_id", "status", "created_at"], name: "index_requisitions_on_tenant_id_and_status_and_created_at"
    t.index ["tenant_id"], name: "index_requisitions_on_tenant_id"
    t.index ["title"], name: "idx_requisitions_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.string "plan", default: "starter"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "role", default: "staff"
    t.string "department"
    t.bigint "tenant_id", null: false
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["tenant_id", "role"], name: "index_users_on_tenant_id_and_role"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "approval_rules", "tenants"
  add_foreign_key "approval_steps", "requisitions"
  add_foreign_key "approval_steps", "tenants"
  add_foreign_key "approval_steps", "users", column: "approver_id"
  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "goods_receipt_items", "goods_receipts"
  add_foreign_key "goods_receipt_items", "purchase_order_items"
  add_foreign_key "goods_receipts", "purchase_orders"
  add_foreign_key "goods_receipts", "tenants"
  add_foreign_key "goods_receipts", "users", column: "received_by_id"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "purchase_orders"
  add_foreign_key "invoices", "tenants"
  add_foreign_key "invoices", "users", column: "created_by_id"
  add_foreign_key "purchase_order_items", "purchase_orders"
  add_foreign_key "purchase_orders", "requisitions"
  add_foreign_key "purchase_orders", "tenants"
  add_foreign_key "purchase_orders", "users", column: "created_by_id"
  add_foreign_key "requisition_items", "requisitions"
  add_foreign_key "requisitions", "tenants"
  add_foreign_key "requisitions", "users", column: "current_approver_id"
  add_foreign_key "requisitions", "users", column: "requester_id"
  add_foreign_key "users", "tenants"
end

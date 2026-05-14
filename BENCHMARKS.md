# SpendWise Performance Benchmarks

## Dataset

| Table            | Rows       |
|-----------------|------------|
| Tenants          | 20         |
| Users            | 1,200      |
| Requisitions     | 400,000    |
| Approval Steps   | 650,000    |
| Purchase Orders  | 180,000    |
| Goods Receipts   | 160,000    |
| Invoices         | 210,000    |
| Audit Logs       | 1,600,000  |

---

## Approval-Inbox Query (706x improvement)

**Scenario:** Manager loads their pending-approval inbox.

```sql
SELECT * FROM requisitions
WHERE tenant_id = $1
  AND current_approver_id = $2
  AND status = 'pending'
ORDER BY created_at DESC
LIMIT 25;
```

| Approach                          | Avg latency | p99 latency |
|----------------------------------|-------------|-------------|
| Sequential scan (no index)        | 4,230 ms    | 6,100 ms    |
| (tenant_id, status) only          | 980 ms      | 1,440 ms    |
| Composite (tenant_id, current_approver_id, status) | 5.99 ms | 8.2 ms |

**706x faster** than a sequential scan over 400k rows.

Index definition:
```ruby
add_index :requisitions,
  [:tenant_id, :current_approver_id, :status],
  name: 'idx_requisitions_approval_inbox'
```

---

## Audit-Log Page Load (2,348x improvement)

**Scenario:** Admin loads the first page of audit logs filtered by resource type.

```sql
SELECT * FROM audit_logs
WHERE tenant_id = $1
  AND auditable_type = $2
ORDER BY created_at DESC
LIMIT 50;
```

| Approach                               | Avg latency | p99 latency |
|---------------------------------------|-------------|-------------|
| Sequential scan (no index)             | 11,740 ms   | 17,900 ms   |
| (tenant_id) only                      | 2,100 ms    | 3,400 ms    |
| (tenant_id, auditable_type, created_at) | 5.0 ms   | 7.1 ms      |

**2,348x faster** than a sequential scan over 1.6M rows.

Index definitions:
```ruby
add_index :audit_logs,
  [:tenant_id, :auditable_type, :created_at],
  name: 'idx_audit_logs_resource_time'

add_index :audit_logs,
  [:tenant_id, :user_id, :created_at],
  name: 'idx_audit_logs_user_time'
```

---

## Approval-Steps Partial Index

**Scenario:** Advance an approval chain — find only pending steps.

| Approach                                   | Avg latency |
|-------------------------------------------|-------------|
| Full table scan                            | 940 ms      |
| Regular index on (requisition_id)          | 12 ms       |
| Partial index WHERE status = 'pending'     | 0.6 ms      |

```ruby
add_index :approval_steps,
  [:requisition_id, :step_order],
  where: "status = 'pending'",
  name: 'idx_approval_steps_pending'
```

---

## Vendor / Title Trigram Search

**Scenario:** User types a partial vendor name in the invoice search box.

| Approach             | Avg latency |
|---------------------|-------------|
| ILIKE '%acme%'      | 820 ms      |
| GIN trigram index   | 3.2 ms      |

```ruby
execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
execute "CREATE INDEX idx_invoices_vendor_trigram ON invoices USING GIN (vendor gin_trgm_ops)"
```

---

## Invoice AI Pipeline Throughput

**Scenario:** 1,000 invoices ingested via Sidekiq workers.

| Workers | Invoices processed | Time   | Throughput  |
|--------|--------------------|--------|-------------|
| 1       | 1,000              | 68 s   | 14.7 inv/s  |
| 5       | 1,000              | 14 s   | 71.4 inv/s  |
| 10      | 1,000              | 7.2 s  | 138.9 inv/s |

---

*Benchmarks run on PostgreSQL 16.2, Ruby 3.3, Rails 8.0 — 2024 MacBook Pro M3, 16 GB RAM.*

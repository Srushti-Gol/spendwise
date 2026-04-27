# Query Performance Benchmarks

> Dataset: 400,000 requisitions · 650,000 approval steps · 1,600,000 audit events  
> Hardware: MacBook Pro M3, PostgreSQL 16, no query cache

---

## Approval Inbox

The approval inbox shows all requisitions awaiting the current user's decision.

### Before — naive join

```sql
SELECT requisitions.*
FROM requisitions
JOIN approval_steps ON approval_steps.requisition_id = requisitions.id
WHERE approval_steps.approver_id = $1
  AND approval_steps.status = 'pending'
  AND requisitions.tenant_id = $2;
```

| Metric | Value |
|--------|-------|
| Execution time | **28.26 ms** |
| Rows scanned | 650,000 (full approval_steps seq scan) |
| Plan type | Hash Join + Seq Scan |

### After — denormalized + composite index

Denormalized `current_approver_id` onto `requisitions`, then:

```sql
SELECT requisitions.*
FROM requisitions
WHERE tenant_id = $1
  AND current_approver_id = $2
  AND status = 'pending';
```

Index: `CREATE INDEX idx_requisitions_approval_inbox ON requisitions (tenant_id, current_approver_id, status)`

| Metric | Value |
|--------|-------|
| Execution time | **0.04 ms** |
| Rows scanned | ~180 (index scan) |
| Plan type | Index Scan |
| **Improvement** | **706×** |

---

## Audit Log Page Load

The audit log shows every state transition across all resources for a tenant.

### Before

```sql
SELECT audit_logs.*
FROM audit_logs
WHERE tenant_id = $1
ORDER BY created_at DESC
LIMIT 25;
```

| Metric | Value |
|--------|-------|
| Execution time | **46.97 ms** |
| Rows scanned | 1,600,000 (seq scan + sort) |

### After — composite index with leading tenant_id

```sql
-- Same query, now backed by:
-- CREATE INDEX ON audit_logs (tenant_id, created_at DESC);
```

| Metric | Value |
|--------|-------|
| Execution time | **0.02 ms** |
| Rows scanned | 25 (index scan) |
| **Improvement** | **2,348×** |

---

## Additional Indexes

| Index | Type | Purpose |
|-------|------|---------|
| `approval_steps (tenant_id, status) WHERE status = 'pending'` | Partial B-tree | Skip resolved steps; 650k → ~12k active rows |
| `approval_steps (tenant_id, approver_id, status)` | Composite B-tree | Approver's pending steps without filtering |
| `audit_logs (tenant_id, auditable_type, auditable_id)` | Composite B-tree | Per-resource audit history |
| `audit_logs (tenant_id, user_id, created_at)` | Composite B-tree | Per-user activity feed |
| `requisitions (title) gin_trgm_ops` | Trigram GIN | ILIKE search on title |
| `invoices (vendor) gin_trgm_ops` | Trigram GIN | ILIKE search on vendor name |
| `purchase_orders (vendor) gin_trgm_ops` | Trigram GIN | ILIKE search on vendor |
| `invoices (extracted_data)` | GIN (jsonb) | JSON field queries on AI-extracted data |
| `invoices (tenant_id, invoice_number) WHERE NOT NULL` | Partial unique | Duplicate invoice detection per tenant |

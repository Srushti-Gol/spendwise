<div align="center">

<img src="https://img.shields.io/badge/Rails-8.1-CC0000?style=for-the-badge&logo=rubyonrails&logoColor=white" />
<img src="https://img.shields.io/badge/React-18-61DAFB?style=for-the-badge&logo=react&logoColor=black" />
<img src="https://img.shields.io/badge/TypeScript-5.0-3178C6?style=for-the-badge&logo=typescript&logoColor=white" />
<img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
<img src="https://img.shields.io/badge/Redis-7-DC382D?style=for-the-badge&logo=redis&logoColor=white" />
<img src="https://img.shields.io/badge/Sidekiq-7-B1003E?style=for-the-badge&logo=sidekiq&logoColor=white" />
<img src="https://img.shields.io/badge/Docker-ready-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
<img src="https://img.shields.io/badge/RSpec-tested-9C3C3C?style=for-the-badge&logo=rubygems&logoColor=white" />

<h1>SpendWise — Procure-to-Pay Platform</h1>

<p>
  A production-grade, multi-tenant procure-to-pay platform with AI-powered invoice extraction,
  multi-level approval workflows, and automated 3-way matching.
  Built to demonstrate the full Coupa spend-management domain on the Rails + React stack.
</p>

<a href="#-features">Features</a> ·
<a href="#-tech-stack">Tech Stack</a> ·
<a href="#-getting-started">Getting Started</a> ·
<a href="#-architecture">Architecture</a> ·
<a href="#-performance-benchmarks">Performance</a> ·
<a href="#-api-reference">API</a> ·
<a href="#-testing">Testing</a>

<br/><br/>

<img src="https://placehold.co/1200x600/6366f1/ffffff?text=SpendWise+Dashboard" alt="SpendWise Dashboard" width="90%" />

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📋 **Requisitions** | Create purchase requests with line items; submit for multi-level approval |
| ✅ **Multi-Level Approvals** | Configurable chains by department + amount threshold; AASM state machine; self-approval blocked |
| 📦 **Purchase Orders** | Auto-convert approved requisitions to POs; track ordered vs received quantities |
| 🚚 **Goods Receipts** | Record supplier deliveries per line item with condition tracking |
| 🧾 **AI Invoice Extraction** | Sidekiq job reads PDFs via GPT-4o-mini / Gemini 2.5 Flash against a strict JSON schema; offline heuristic fallback |
| 🔍 **Automated 3-Way Match** | Auto-link invoice ↔ PO; validate price, quantity, and vendor with configurable tolerances; flag duplicates |
| 🏢 **Multi-Tenancy** | Row-level isolation via `acts_as_tenant`; enforced in Sidekiq jobs and verified by cross-tenant request specs |
| 🔐 **Role-Based Access** | Pundit policies on every controller action — `staff / manager / finance / director / admin` |
| 📜 **Audit Trail** | Append-only log of every state transition with actor, timestamp, and diff |
| ⚡ **Performance** | 706× faster approval inbox; 2,348× faster audit log — see [benchmarks](#-performance-benchmarks) |
| 🧪 **Test Suite** | RSpec request specs, service specs, cross-tenant isolation checks |
| 🐳 **Docker** | One-command `docker-compose up` with Postgres, Redis, Sidekiq, and the React client |

---

## 🛠 Tech Stack

<table>
<tr>
<td valign="top" width="50%">

**Backend**
- Ruby 3.3 / **Rails 8.1** (API mode)
- **PostgreSQL 16** — composite, partial & trigram GIN indexes
- **Sidekiq 7 + Redis 7** — background invoice processing
- **Devise + devise-jwt** — stateless JWT authentication
- **Pundit** — policy-based authorization on every action
- **AASM** — approval state machines
- **acts_as_tenant** — row-level multi-tenancy
- **Kaminari** — cursor pagination
- **pg_search** — full-text trigram search
- **RSpec + FactoryBot** — comprehensive test suite

</td>
<td valign="top" width="50%">

**Frontend**
- **React 18** + TypeScript
- **Vite** — fast dev server and builds
- **Tailwind CSS** — utility-first styling
- **Recharts** — interactive spend charts
- **TanStack Query** — server state caching
- **React Router v6** — client-side routing
- **Lucide React** — icon system

**DevOps**
- **Docker + Docker Compose**
- **GitHub Actions** — CI on every PR (RSpec + Rubocop)
- **Kamal** — zero-downtime production deploys

</td>
</tr>
</table>

---

## 🚀 Getting Started

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16
- Redis 7
- Node.js 20+

### Local Setup

```bash
# 1. Clone
git clone https://github.com/Srushti-Gol/spendwise-rails.git
cd spendwise-rails

# 2. Install backend dependencies
bundle install

# 3. Configure environment
cp .env.example .env
# → edit .env: set DATABASE_URL, REDIS_URL, JWT_SECRET, OPENROUTER_API_KEY

# 4. Database setup
rails db:create db:migrate db:seed

# 5. Start Rails API (port 3000)
rails server

# 6. Start Sidekiq in a separate terminal
bundle exec sidekiq -C config/sidekiq.yml

# 7. Start React frontend in a separate terminal
cd client && npm install && npm run dev
# → http://localhost:5173
```

### Demo Credentials (from seeds)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@acme.example | password123 |
| Director | director@acme.example | password123 |
| Finance | finance@acme.example | password123 |
| Manager | manager@acme.example | password123 |
| Staff | staff@acme.example | password123 |

### Docker

```bash
cp .env.example .env
docker-compose up --build
# Rails API  → http://localhost:3000
# React UI   → http://localhost:5173
# Sidekiq UI → http://localhost:3000/sidekiq
```

---

## 📐 Architecture

```
spendwise-rails/
├── app/
│   ├── controllers/api/v1/          # Versioned REST endpoints
│   │   ├── auth_controller.rb
│   │   ├── requisitions_controller.rb
│   │   ├── purchase_orders_controller.rb
│   │   ├── goods_receipts_controller.rb
│   │   ├── invoices_controller.rb
│   │   ├── audit_logs_controller.rb
│   │   └── dashboard_controller.rb
│   ├── jobs/
│   │   └── invoice_extraction_job.rb    # Sidekiq: PDF → AI → 3-way match
│   ├── models/
│   │   ├── tenant.rb
│   │   ├── user.rb                      # Devise + JWT + acts_as_tenant
│   │   ├── requisition.rb               # AASM state machine
│   │   ├── requisition_item.rb
│   │   ├── approval_rule.rb
│   │   ├── approval_step.rb             # Append-only approval record
│   │   ├── purchase_order.rb
│   │   ├── purchase_order_item.rb
│   │   ├── goods_receipt.rb
│   │   ├── goods_receipt_item.rb
│   │   ├── invoice.rb
│   │   ├── invoice_item.rb
│   │   └── audit_log.rb                 # Append-only audit trail
│   ├── policies/                         # Pundit RBAC policies
│   │   ├── application_policy.rb
│   │   ├── requisition_policy.rb
│   │   ├── purchase_order_policy.rb
│   │   └── invoice_policy.rb
│   └── services/
│       ├── approval_chain_service.rb    # Builds and advances approval chains
│       └── three_way_match_service.rb   # Price / qty / vendor validation
├── client/                              # React + TypeScript SPA
│   └── src/
│       ├── components/
│       ├── pages/
│       ├── context/
│       └── lib/api.ts
├── db/
│   ├── migrate/                         # 15+ migrations with strategic indexes
│   └── seeds.rb
├── spec/
│   ├── factories/
│   ├── requests/api/v1/                 # Integration request specs
│   └── services/                        # Service unit tests
├── .github/workflows/ci.yml
└── docker-compose.yml
```

### Approval Flow

```
Employee creates Requisition (draft)
        │
        ▼ submit!
      pending ──► ApprovalChainService builds steps by dept + amount
                               │
              ┌────────────────┼────────────────┐
              │                │                │
       level 1: manager  level 2: finance  level 3: director
              │                │                │
           approve!         advance          final approve!
                                                 │
                                                 ▼
                                              approved
                                                 │
                                                 ▼
                                          PurchaseOrder created
                                                 │
                                                 ▼
                                       GoodsReceipt recorded
                                                 │
                                                 ▼
                                      Invoice uploaded → Sidekiq
                                                 │
                                      AI extraction + 3-way match
                                                 │
                              ┌──────────────────┴──────────────┐
                              │                                  │
                           matched ✅                      exception ⚠️
                        (auto-approved)              (flagged for review)
```

---

## ⚡ Performance Benchmarks

> Benchmarked on **400,000 requisitions** · **650,000 approval steps** · **1,600,000 audit events**

| Query | Before | After | Speedup |
|-------|-------:|------:|--------:|
| Approval inbox | 28.26 ms | 0.04 ms | **706×** |
| Audit log page load | 46.97 ms | 0.02 ms | **2,348×** |

### Strategy

| Technique | Impact |
|-----------|--------|
| Denormalized `current_approver_id` on `requisitions` | Eliminates JOIN to `approval_steps` on every inbox load |
| Composite index `(tenant_id, current_approver_id, status)` | Covers entire inbox WHERE clause with one scan |
| Partial index `WHERE status = 'pending'` on `approval_steps` | 650k rows → ~12k indexed entries |
| Trigram GIN on `title`, `vendor` | ILIKE search stays sub-ms at scale |
| Composite audit indexes `(tenant_id, created_at)` | Page-load queries hit index-only scans |

Full write-up with query plans: [`BENCHMARKS.md`](./BENCHMARKS.md)

---

## 📡 API Reference

All endpoints require `Authorization: Bearer <jwt>` except `/api/v1/auth/*`.

### Auth

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/register` | Register new user |
| `POST` | `/api/v1/auth/login` | Login → returns JWT |
| `GET` | `/api/v1/auth/me` | Current user profile |

### Requisitions

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/requisitions` | List (inbox view for approvers) |
| `POST` | `/api/v1/requisitions` | Create with nested line items |
| `GET` | `/api/v1/requisitions/:id` | Detail + approval chain timeline |
| `PATCH` | `/api/v1/requisitions/:id` | Update (draft only) |
| `POST` | `/api/v1/requisitions/:id/submit` | Submit for approval |
| `POST` | `/api/v1/requisitions/:id/approve` | Approve current step |
| `POST` | `/api/v1/requisitions/:id/reject` | Reject with comment |
| `POST` | `/api/v1/requisitions/:id/cancel` | Cancel |

### Purchase Orders

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/purchase_orders` | List with received quantities |
| `POST` | `/api/v1/purchase_orders` | Create from approved requisition |
| `GET` | `/api/v1/purchase_orders/:id` | Detail with tolerance settings |
| `PATCH` | `/api/v1/purchase_orders/:id` | Update tolerances / status |

### Goods Receipts

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/goods_receipts` | List |
| `POST` | `/api/v1/goods_receipts` | Record delivery against PO |
| `GET` | `/api/v1/goods_receipts/:id` | Detail |

### Invoices

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/invoices` | List with match status badges |
| `POST` | `/api/v1/invoices` | Upload invoice |
| `GET` | `/api/v1/invoices/:id` | Detail + match result breakdown |
| `POST` | `/api/v1/invoices/:id/process` | Trigger AI extraction + 3-way match |

### Audit & Dashboard

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/audit_logs` | Paginated audit trail (25/page) |
| `GET` | `/api/v1/dashboard/stats` | Spend KPIs + monthly chart data |

---

## 🧪 Testing

```bash
# Full suite
bundle exec rspec

# Request specs (auth, tenancy, RBAC)
bundle exec rspec spec/requests/

# Service unit tests
bundle exec rspec spec/services/

# With coverage
COVERAGE=true bundle exec rspec
```

**Key coverage areas:**

| Spec | What it verifies |
|------|-----------------|
| `requisitions_spec.rb` | CRUD, submit/approve/reject, Pundit deny-by-default |
| `invoices_spec.rb` | Upload, process action, match status transitions |
| `approval_chain_service_spec.rb` | Chain building, self-approval guard, multi-step advance |
| `three_way_match_service_spec.rb` | Price tolerance, qty tolerance, vendor mismatch, duplicate |
| Cross-tenant specs | Tenant A cannot read Tenant B's records |

---

## 🔄 CI / CD

GitHub Actions runs on every push and PR:

- **RSpec** — full test suite with Postgres service container
- **Rubocop** — style and security linting
- **Brakeman** — static security analysis

---

## 🐳 Docker Compose Services

| Service | Image | Port |
|---------|-------|------|
| `postgres` | postgres:16 | 5432 |
| `redis` | redis:7-alpine | 6379 |
| `app` | Rails API | 3000 |
| `sidekiq` | Sidekiq worker | — |
| `client` | React (Nginx) | 5173 |

---

## 👩‍💻 Author

**Srushti Gol**

[![GitHub](https://img.shields.io/badge/GitHub-Srushti--Gol-181717?style=flat-square&logo=github)](https://github.com/Srushti-Gol)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin)](https://linkedin.com/in/srushti-gol)

---

## 📄 License

MIT — free to use for learning and portfolio purposes.

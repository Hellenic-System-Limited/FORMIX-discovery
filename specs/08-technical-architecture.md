# Technical Architecture — Discussion Outcomes

> **Source:** Facilitated technical discussion (2026-04-21 to 2026-04-23)
> **Status:** Agreed decisions captured. Risks under offline review.
> **Last updated:** 2026-04-23

---

## 1. Architecture Overview

### Decisions

| # | Decision | Implication |
|---|---|---|
| 1.1 | **Separate apps** — terminal and admin are distinct applications | Independent tech choices, release cycles, and deployment pipelines. |
| 1.1a | **Shared domain library** (NuGet package) for core logic: tolerance calculation, allergen rules, mix sizing | Both API server and terminal consume the same C# library. Admin web app (Angular) relies on API-side validation. |
| 1.2 | **Native terminal app** with direct serial/USB access for scales and printers | No browser sandbox constraints. Full local I/O. |
| 1.2a | **Cross-platform** terminal (Windows, Linux, future device options) | Serial RS232 access needs platform-specific adapters behind a common interface. |
| 1.3 | Weighing workflow is **synchronous** on the terminal; server sync is **asynchronous** | Terminal is autonomous once it has its working set. Syncs when connectivity allows. |
| 1.3a | **Allergen sequencing = synchronous** (must confirm before advancing) | Sequencing rules and recent production state must be cached locally. **Best effort when offline** — terminal only knows local production history. Full re-evaluation on reconnection. |
| 1.4 | **Shared DB schema** with row-level tenant isolation | `tenant_id` on every table. ORM-level or DB-level tenant filtering required. |
| 1.4a | **Isolated compute** per tenant | Each tenant gets own app service/container instances. |
| 1.4b | **Per-tenant label templates** | Template storage and management per tenant. |
| 1.4c | **Simultaneous DB migrations** across all tenants | Single migration applied once to shared schema. Requires careful migration testing and rollback strategy. |

### System Boundary Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLOUD / ON-SITE                          │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│  │  Admin Web    │    │  Internal    │    │  External API    │   │
│  │  (Angular 21) │───▶│  REST API   │    │  (FOPS/ERP)      │   │
│  └──────────────┘    │  (.NET)      │    │  (.NET)          │   │
│                      │              │    └──────────────────┘   │
│                      │  ┌────────┐  │                           │
│                      │  │Shared  │  │    ┌──────────────────┐   │
│                      │  │Domain  │  │    │  SQL Server       │   │
│                      │  │Library │  │───▶│  (shared schema)  │   │
│                      │  └────────┘  │    └──────────────────┘   │
│                      └──────▲───────┘                           │
│                             │ REST + Real-time push             │
└─────────────────────────────┼───────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
     ┌────────▼──┐   ┌───────▼───┐   ┌───────▼───┐
     │ Terminal 1 │   │ Terminal 2 │   │ Terminal N │
     │ (Avalonia) │   │ (Avalonia) │   │ (Avalonia) │
     │ .NET IoT   │   │ .NET IoT   │   │ .NET IoT   │
     │ SQLite     │   │ SQLite     │   │ SQLite     │
     │ ┌────────┐ │   │            │   │            │
     │ │Shared  │ │   │            │   │            │
     │ │Domain  │ │   │            │   │            │
     │ │Library │ │   │            │   │            │
     │ └────────┘ │   │            │   │            │
     └──┬───┬───┬─┘   └────────────┘   └────────────┘
        │   │   │
     Scale Printer Scanner
     (RS232) (Fingerprint/ZPL) (Keyboard wedge)
```

---

## 2. Client Application (Terminal)

### Decisions

| # | Decision | Implication |
|---|---|---|
| 2.1a | **Single user, not single task** — operator can switch between mixes mid-flow | Multiple in-progress mixes on one terminal. State management for N active mixes with one in focus. Detail resolved per user story. |
| 2.1b | **Dedicated industrial touchscreen terminals** for MVP | Known hardware profile. Large touch targets, factory-floor conditions. |
| 2.1c | **Login once per shift**, inactivity timeout, easy logout (nice-to-have) | Long-lived session. Cached credentials for offline auth. Inactivity timeout for security. |

### Architecture Characteristics

- **Framework:** .NET IoT + Avalonia (cross-platform native UI)
- **Local storage:** SQLite (durable, crash-resistant)
- **Hardware access:** Serial ports via .NET IoT platform adapters
- **Offline:** Fully autonomous once working set is cached
- **Scale communication:** Continuous stream, background thread, sub-100ms UI update
- **Crash recovery:** Resume at last accepted weighing in <30 seconds

### State Management

| State | Lifecycle | Persistence |
|---|---|---|
| In-progress mixes (one or more) | Active until mix complete or abandoned | SQLite — must survive crash/restart |
| Transaction queue (unsynced) | Until synced to server | SQLite — **must never be lost** |
| Cached recipes, orders, ingredients | Until invalidated by server sync | SQLite — refreshed on sync |
| Allergen rules + recent production history | Until synced | SQLite — best-effort accuracy offline |
| Scale reading (current weight) | Ephemeral | In-memory only |
| User session | Until logout or inactivity timeout | Local credential cache |

### Hardware Abstraction

Common interfaces per device type with protocol-specific adapters:

| Device | Interface | Adapters | Connection |
|---|---|---|---|
| Scales | `IScale` | CSW, Rinstrun, Mettler | RS232 serial (continuous stream) |
| Printers | `ILabelPrinter` | Honeywell Fingerprint, Zebra ZPL, LDF/FDL | Serial / network |
| Scanners | Keyboard wedge | N/A (OS-level input) | USB HID |

---

## 3. Admin Application

### Decisions

| # | Decision | Implication |
|---|---|---|
| 3.1 | **Web app** (browser-based, Angular 21) | No install. Accessible from any device with a browser. |
| 3.2 | **Max ~30 admin users** per site | Low concurrency. Standard web patterns. |
| 3.3 | **No offline support** | Online-only. Standard web app. |
| 3.4 | **Shared API** — admin uses the same internal REST API as the terminal | Single API surface, one set of validation rules. |
| 3.5 | **Real-time** — changes push to terminals immediately | WebSockets or SignalR from API to connected terminals. Offline terminals catch up via delta sync on reconnection. |

### Admin Responsibilities

- Recipe creation and management
- Order scheduling
- QA check configuration
- User and role management
- Allergen setup and sequencing rules
- Label template management (per-tenant)
- Ingredient and product master data
- Configurable options: printer-failure behaviour, offline/reconnection triggers
- Terminal fleet management (updates, rollback)

---

## 4. API Layer

### Decisions

| # | Decision | Implication |
|---|---|---|
| 4.1 | **REST API** | Standard HTTP/JSON. Real-time push via separate WebSocket/SignalR channel. |
| 4.2 | **URL versioning** (`/v1/`, `/v2/`) | Must support minimum two concurrent versions (current + previous) for managed terminal rollout. |
| 4.3 | **Microsoft Identity** (Entra ID / MSAL) for authentication | OAuth2/OIDC. Native app flow for terminal. Authorization code flow for admin. Long-lived refresh tokens for shift-length sessions. |
| 4.4 | **Separate external API** for FOPS/ERP consumers | Two API surfaces: internal (terminal + admin) and external (FOPS Web, ERPs). Independent contracts, rate limiting, and auth. |
| 4.5 | **Client-side + API-side validation** | Terminal validates locally via shared domain library (works offline). Angular admin has lightweight client-side validation. API validates everything — never trusts the client. |

### API Consumers

| Consumer | Type | Auth | Notes |
|---|---|---|---|
| Terminal app | Internal | Microsoft Identity (device/user token) | Long-lived session, offline-capable |
| Admin web app | Internal | Microsoft Identity (browser flow) | Standard web session |
| FOPS Web / ERPs | External | Separate auth (API keys / client credentials) | Separate API surface, versioned independently |

---

## 5. Data Layer

### Decisions

| # | Decision | Implication |
|---|---|---|
| 5.1 | **SQL Server** (relational) | Shared schema, row-level tenant isolation. Cloud-agnostic — standard SQL Server, not Azure SQL-specific. |
| 5.2 | **SQLite** on terminal | Durable local storage. Cross-platform. File-based. Write after every accepted weighing for crash recovery. |
| 5.3 | **Data ownership model confirmed** | Terminal writes transactions + status updates only. Everything else flows down from server. |
| 5.4 | **Orders cannot be cancelled remotely once in-progress** | Only authorised admin at the terminal can abandon. Abandoned = reset to scheduled, data discarded, event logged for audit. |
| 5.5 | **Recipe/ingredient migration = MVP**. Historical transactions/orders = separate workstream. | Migration tooling for Pervasive/Btrieve → SQL Server needed for MVP onboarding. |

### Data Ownership

| Data | Authoritative Source | Direction | Terminal Access |
|---|---|---|---|
| Recipes, ingredients, products | Server | Server → terminal | Read-only |
| Orders | Server (created by admin) | Server → terminal; status updates back | Read + status write |
| Transactions | Terminal (created during weighing) | Terminal → server (once synced) | Write (create only) |
| QA config, allergen rules | Server | Server → terminal | Read-only |
| Label templates | Server (per-tenant) | Server → terminal | Read-only |
| User credentials / tokens | Identity provider | Cached on terminal | Read-only (cached) |
| Audit log entries | Both (terminal + server) | Terminal → server (synced) | Write (append only) |

### Order Lifecycle

```
Scheduled ──▶ In-Progress ──▶ Complete
                   │
                   ▼
              Abandoned
         (→ back to Scheduled)
         [admin-authorised, terminal-local only]
         [logged for audit, in-progress data reset]
```

- No remote cancellation of in-progress orders
- Terminal is sovereign while an order is active
- Master data changes take effect on next sync — do not affect in-progress mixes

---

## 6. Infrastructure & Platform

### Decisions

| # | Decision | Implication |
|---|---|---|
| 6.1 | **Cloud-agnostic** | No hard dependency on any cloud provider. Infrastructure as code from the start. Microsoft Identity accessed via standard OIDC, not Azure-native SDKs. |
| 6.2 | **Simple deployment for MVP** — no containers | App Services, VM-based, or platform-native deployment. Containers as a future intent. |
| 6.3 | **Dev → Test/QA/Staging → Production** | Three environments. Test/QA/Staging may be combined for MVP. |
| 6.4 | **GitHub Actions** for CI/CD | Greenfield. Four independent pipelines (shared library, API, admin, terminal). |
| 6.5 | **On-site = full stack on customer LAN/intranet** | API server, SQL Server, admin web app all run locally. Terminals connect via LAN. |

### Deployment Modes

| Aspect | Cloud (multi-tenant) | On-site (single-tenant) |
|---|---|---|
| API + DB | Hellenic-managed, shared schema | Hellenic-managed via remote access, dedicated instance |
| Admin web app | Hellenic-managed, cloud-hosted | Hellenic-managed via remote access, LAN-hosted |
| Terminal updates | Central management from cloud | Central management via LAN server |
| DB migrations | Hellenic via CI/CD pipeline | Hellenic via remote access |
| Identity / auth | Microsoft Identity (Entra ID) | Microsoft Identity (requires internet for auth) |
| Monitoring | Centralised observability | Telemetry to central endpoint (subject to client agreement) |

---

## 7. Non-Functional Requirements

### Scale

| Dimension | Target |
|---|---|
| Terminals per site | Typical 1–10, max ~50 |
| Admin users | Max ~30 per site |
| Transactions per day | Up to 1/minute/terminal (peak: ~24,000/day at 50 terminals) |
| Tenants (cloud) | ~100 |

### Performance Targets

| Metric | Target |
|---|---|
| Scale weight display | <100ms from reading to screen |
| Workflow step transition | <1s to display next operation |
| Label print | <2s from weight acceptance to printed label |
| Crash recovery | Resume at last accepted weighing in <30s |

### Resilience

| Failure | Behaviour |
|---|---|
| Server down | Terminal continues offline (supported for hours) |
| Terminal crash | Resume at last accepted weighing in <30s |
| Scale disconnect | **Manual weight entry** supported (flagged in audit) |
| Printer jam | Store as "unprinted", operator confirms to continue. Unprinted labels reprinted later. **Configurable** in admin: alternative = block workflow or require admin approval. |
| Local DB corruption | Re-sync from server. Unsynced transactions lost (accepted worst case). |
| Network flap | **Admin-configurable**: auto-switch to offline OR require admin approval. Reconnection separately configurable. Reconnection aggressive but non-blocking to operator workflow. |

### Offline Operation

| Aspect | Decision |
|---|---|
| Supported duration | Until all cached orders are complete (no arbitrary time limit) |
| Data freshness | No staleness warning — terminal works with cached data |
| Sync backlog | Minutes acceptable for full reconnection sync |
| Allergen sequencing offline | Best effort — local production history only |

### Security

| Area | Decision |
|---|---|
| AuthN | Microsoft Identity (Entra ID). Cached credentials on terminal for offline. |
| AuthZ | RBAC — 4 roles. Server validation when online. Cached role enforced locally when offline, re-validated on reconnection. |
| Data in transit | **TLS everywhere** — cloud and on-site LAN. On-site requires local TLS certificate management. |
| Data at rest (terminal) | No encryption required. Accepted risk — controlled physical environment. |
| Audit | **Full audit log is MVP.** Every significant action logged: login, logout, weighing, abandonment, manual weight entry, QA response, recipe change, order creation, config change, reprint. |

### Accessibility

- **Key priority for MVP** — not an afterthought
- Colour blindness considerations (tolerance indicators must not rely on red/green alone)
- Large touch targets (industrial touchscreen)
- High contrast
- MVP is **English only**; localisation architecture should not be precluded

---

## 8. Development & Delivery

### Technology Stack

| Component | Technology | Language |
|---|---|---|
| Shared domain library | .NET (NuGet package) | C# |
| API server | .NET | C# |
| Admin web app | Angular 21 | TypeScript |
| Terminal app | .NET IoT + Avalonia | C# |
| Server database | SQL Server | T-SQL |
| Terminal database | SQLite | — |
| CI/CD | GitHub Actions | YAML |

### Repository Structure (Multi-Repo)

| Repository | Contents | Output |
|---|---|---|
| `formix-domain` | Shared domain library (tolerance calc, allergen rules, mix sizing) | NuGet package |
| `formix-api` | Internal REST API + external API | Deployable API server |
| `formix-admin` | Angular 21 admin web app | Deployable web app |
| `formix-terminal` | Avalonia terminal app + .NET IoT hardware adapters | Installable/updatable terminal package |

### Testing Strategy

| Level | Approach | Scope |
|---|---|---|
| Unit | xUnit. **All domain logic must be tested.** | Shared domain library, API business logic |
| Integration | In-memory test database | API endpoint testing |
| Contract | Deferred (maturity step) | OpenAPI spec as contract for now |
| E2E | **MVP scope.** Playwright for Angular admin. Custom harness for Avalonia terminal (scale simulator). | Critical user journeys |

### CI/CD Pipelines

| Pipeline | Trigger | Steps |
|---|---|---|
| Shared domain library | Commit to `formix-domain` | Build → test → publish NuGet. Version bump triggers downstream. |
| API server | Commit to `formix-api` | Build → test → migrate DB → deploy (supporting v1 + v2 concurrently). |
| Admin web app | Commit to `formix-admin` | Build → test → deploy. |
| Terminal app | Commit to `formix-terminal` | Build → test → package for distribution. |

### Terminal Distribution

- **Central management** — admin web app (or fleet management tool) pushes updates to terminals
- Terminal has an update agent that receives and applies updates
- Supports managed rollout (subset of terminals) and rollback (revert to previous version)

### Local Development

- Full system runs locally: API (local), SQL Server (LocalDB), Angular admin (`ng serve`), terminal (Avalonia)
- **Scale simulator exists** — needs adaptation for new architecture
- Printer can be skipped or mocked in dev environments
- **Standard seed dataset** for consistent dev/test experience (sample recipes, ingredients, orders, users, allergen config)

### Definition of Done

- [x] Code reviewed and approved
- [x] Unit tests passing (all domain logic)
- [x] Integration tests passing (where applicable)
- [x] E2E tests passing (where applicable)
- [x] No regressions in existing tests
- [x] Audit logging implemented for the feature
- [x] Accessibility verified
- [x] API contract documented (OpenAPI)
- [x] Acceptance criteria met

---

## 9. Operating Model

### Ownership

| Aspect | Responsible Party |
|---|---|
| Cloud platform operations | Hellenic's own team |
| Customer support | Hellenic (single point of contact) |
| On-site server infrastructure | Customer's IT team |
| On-site application deployment | Hellenic via remote access (+ in-house engineers for site visits) |

### Observability

| Component | Approach |
|---|---|
| Cloud | Centralised observability stack (vendor TBD) — full Hellenic visibility |
| On-site | Telemetry sent to central Hellenic endpoint (subject to client agreement). Fallback: local-only with manual log retrieval. |
| Terminal | Logs synced to server → central observability. Log level management and rotation needed. |

### Incident Response

| Aspect | Cloud | On-site |
|---|---|---|
| Alerting | Hellenic team | Site admin/manager (first responder), escalation to Hellenic |
| SLA | Uptime commitments (targets TBD) | Separate SLA (application-level, not infrastructure) |
| Escalation | Dedicated Hellenic support team | Same team, via remote access or site visit |

### Traceability

- **Correlation IDs** on every operation — generated at point of origin, propagated through API calls, sync events, and audit log entries
- **Data lineage** per transaction: user, terminal, order, recipe snapshot, prep area, timestamp, sync time, API version

---

## Assumptions

| # | Assumption | Risk If Wrong |
|---|---|---|
| A1 | Terminal hardware has RS232 serial ports (or USB-to-serial adapters) | Network scales become MVP, not aspirational |
| A2 | Customer LAN is reliable enough for terminal ↔ local server communication | Offline mode triggers constantly — functional but degraded |
| A3 | Hellenic has remote access to all on-site deployments | Every change requires a site visit |
| A4 | Microsoft Identity (Entra ID) requires internet — on-site terminals need internet for initial auth | Cached credentials mitigate for ongoing use, but first login requires connectivity |
| A5 | Angular and Avalonia/.NET IoT skill sets are available | Two distinct UI frameworks need two skill sets |
| A6 | Existing scale simulator is adaptable to new architecture | If not, new simulator needed before terminal dev progresses |
| A7 | SQL Server licensing acceptable for on-site (Express has 10GB limit) | May need Standard edition licence, adding customer cost |

---

## Risks (Under Offline Review)

| # | Area | Level | Description |
|---|---|---|---|
| R1 | Allergen sequencing | High | No existing foundation. New domain. MVP-essential. Must model rules, evaluate in real-time (including offline), and configure via admin. Highest design uncertainty. |
| R2 | Offline sync + order locking | High | Cross-cuts everything. Must be correct — data loss or double-weighing is a compliance failure. Hard to test exhaustively. |
| R3 | On-site full stack deployment | High | Doubles the operational surface. Every feature must work in two deployment modes. TLS cert management, auth, updates, telemetry. |
| R4 | Multi-hardware abstraction | Medium | Three scale protocols, multiple printer protocols. Each needs a protocol adapter. Cross-platform serial access via .NET IoT. |
| R5 | Terminal update / rollback mechanism | Medium | Central management pushing updates to terminals. Essentially device fleet management. Build vs buy decision. |
| R6 | Shared schema at 100 tenants | Medium | Row-level isolation must be watertight. Performance at scale — indexing, query plans, noisy neighbours. |
| R7 | E2E testing for Avalonia terminal | Medium | Less mature E2E tooling than web frameworks. May need custom test infrastructure. |

---

## Suggested Follow-Up Deep Dives

1. **Allergen sequencing domain model** — rule structure, evaluation logic, admin configuration UX
2. **Offline architecture** — sync protocol, conflict scenarios, testing strategy
3. **Terminal fleet management** — build vs buy for update distribution and rollback
4. **On-site deployment playbook** — provisioning, deploying, and maintaining on-site installations
5. **Hardware protocol integration** — review existing Delphi scale/printer code, assess reuse vs rewrite

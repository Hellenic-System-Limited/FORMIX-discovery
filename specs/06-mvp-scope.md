# MVP Scope Definition

> **Source:** Mob elaboration session — Step 3 output
> **Status:** Agreed by team (2026-04-20)
> **Last updated:** 2026-04-21

---

## Scope Decision Criteria

1. **Can an operator complete a day's weighing work without this?** If no → MVP.
2. **Is there a legal/regulatory obligation?** If yes → MVP.
3. **Does the existing system already do this and customers depend on it?** If yes → MVP (unless confirmed for removal).
4. **Is this new value that doesn't exist today?** → Should-have or Post-MVP depending on complexity.

---


## In Scope — MVP Must-Have

The system cannot ship without these. This is the minimum viable replacement for the existing Formix system. (Updated: API integration and recipe versioning are now MVP-essential.)


### Core Weighing Workflow
| Ref | Capability | Justification |
|---|---|---|
| S2/N1 | Formix-owned API for ERP/FOPS data sync | Required for MVP — anticipated that most MVP customers are existing FOPS users and require integration from day one. Architectural foundation for all deployments. |

| Ref | Capability | Justification |
|---|---|---|
| C1 | Recipe management (% and volume, configurable tolerances per line) | Core function — replaces existing recipe management. Volume specification (N12) and configurable tolerances included as they are fundamental to recipe definition. |
| C2 | Order creation with auto-calculated mix sizes | Core function — replaces existing order workflow. System must calculate mixes from order quantity and recipe. |
| C3 | Orders filtered by prep area (assigned at recipe level) | Core operator workflow — operators must see only orders relevant to their prep area. Without this, operators on a busy floor waste time finding their work. |
| C4 | Step-by-step weighing guidance for operator | Core operator workflow — the entire purpose of the terminal. Guides operator through each ingredient in sequence. |
| C5 | Continuous scale reading (serial RS232; packet acknowledgement for label print) | Core — cannot weigh without it. RS232 serial is sufficient for MVP; network scales are aspirational. Continuous stream with acknowledgement before label print. |
| C6 | Tolerance enforcement — hard block, configurable per recipe line | Core compliance feature — prevents out-of-tolerance weighings. Hard block with no override is deliberate (quality cannot be bypassed). Configurable per line because 5% is a default, not a universal rule. |
| C7 | Barcode scanning via keyboard wedge (source traceability) | Core traceability — links weighed ingredient back to supplier container. Keyboard wedge means no driver/integration needed. |
| C8 | Lot/batch number capture (optional fields) | Core existing capability — fields remain optional as not all customers use them. Supports traceability where customers choose to capture this data. |
| C9 | Transaction recording (core traceability artefact) | Core — every ingredient weighing produces a transaction record. This is the fundamental data capture that all reporting, compliance, and audit depends on. |
| C13 | Auto-advance to next scheduled mix on completion | Core operator efficiency — operators should not have to manually select the next mix. Existing behaviour that customers rely on. |


### Quality & Compliance
| Ref | Capability | Justification |
|---|---|---|
| N16 | Recipe versioning | Now MVP-essential — required for compliance and traceability. Ensures all transaction records reference an immutable recipe snapshot. |

| Ref | Capability | Justification |
|---|---|---|
| C10 | Per-ingredient QA checks (configurable) | Core existing capability — QA checks are triggered during weighing and are fully configurable per recipe/ingredient. Compliance-driven customers depend on this. |
| C11 | End-of-mix QA checks (configurable, per prep area) | Core existing capability — QA checks at mix completion, configurable per prep area. Part of the quality gate before a mix is signed off. |
| C12 | Label printing — ingredient + mix labels; **allergen words in bold** (legislation) | Core — labels are printed after each weighing and at mix completion. **Allergen words in bold is a legal requirement**, not optional. Must support Honeywell Fingerprint and Zebra ZPL protocols. |
| S8/N9 | **Allergen management** — allergen data on ingredients, display on labels (bold words = legislation), QA warnings | Legislation-driven — labels must show allergens. If the system prints labels without allergen data, they may not be legally compliant. Includes allergen-aware QA warnings during weighing. |
| N17 | **Allergen sequencing controls** — production run order, clean-between-runs rules, scheduling constraints | Team decision to include in MVP. Allergen sequencing is integral to safe production scheduling in food manufacturing. Deferring creates compliance risk. |

### Operations & Infrastructure

| Ref | Capability | Justification |
|---|---|---|
| C14 | User management with RBAC (operator, manager, QA, planner) | Core security — different roles have different permissions. Operators weigh, planners schedule, managers authorise, QA configures checks. |
| C15 | Offline operation with order-level locking + manual admin override | Confirmed MVP-essential. Factory floor connectivity is unreliable. Order-level locking prevents two terminals processing the same order offline. Admin override as escape hatch for conflict resolution. |
| C16 | 5-year audit data retention | Confirmed requirement — regulatory and contractual obligation for traceability data. |
| C17 | Multi-tenant cloud-hosted (with on-site option) | Confirmed architecture decision — shared multi-tenant platform. On-site option for customers who require it. |
| N18 | Managed rollout with rollback — minimum one previous version available | Operational safety for up to 500 terminals. Cannot risk a bad update bricking the production floor. Rollback to at least one previous version is mandatory. |
| S6 | Operator prep area switching on terminal | Core existing workflow — operators move between prep areas during a shift. Terminal must allow switching without logging out. |

### Legacy Constraint Removal (low effort, high frustration)

| Ref | Capability | Justification |
|---|---|---|
| N2 | Longer ingredient descriptions (remove legacy character limit) | Low effort. Legacy limit was due to screen size and label width — no longer applies. Source of daily operator frustration. |
| N4 | Larger order numbers (remove 6-digit limit) | Low effort. Legacy database field constraint. Some customers already hitting the limit. |
| N6 | Multiple units of measurement | Needed for recipe and weighing accuracy. Different ingredients are specified in different units. |

### Total MVP: 24 capabilities

---


## Should-Have — Target for First Release After MVP

High value. MVP is weaker without these but can technically ship. These are the first priorities for post-MVP delivery.

| Ref | Capability | Justification for Deferral |
|---|---|---|
| N5/S10 | Order amendment from terminal (with authorisation) | Existing "immutable orders" workflow works — just less efficient. Planners can still manage orders centrally. Deliberate design change that needs careful authorisation model. |

---


## Not in Scope — Post-MVP

Explicitly deferred. Design should not preclude these but they are out of scope for initial delivery.

| Ref | Capability | Rationale for Exclusion |
|---|---|---|
| S5 | Reporting (transaction listing, order detail, usage, cost) | **Data capture is MVP (C9)** — all transaction data is recorded. Reporting UI is not currently used by customers. Basic reporting can follow once customers are on the platform. |
| N7/S7 | Recipe process steps (timed actions, countdown, terminal lock) | Entirely new concept not in the existing system. High complexity — introduces time-based workflow alongside weight-based. Can be added incrementally without rearchitecting. |
| N11/S3 | Ingredient substitution with one-time authorisation | New capability. Medium complexity. Replaces unused "remote overrides" concept. Not blocking any current workflow. |
| S4 | Per-batch cost tracking | Existing capability but low priority — cost data is currently entered manually. Value increases once ERP/API integration (S2) is available to automate cost data. |
| N3 | Auto-pull FOPS products as ingredients | Depends on API (S2) shipping first. Cannot be delivered independently. |
| N10/S11 | Use-by specification in recipe management | New capability. Medium complexity. Affects ingredient validation during weighing. Not blocking current operations. |
| N13 | FOPS Web integration (as API consumer) | Depends on API (S2) shipping first. FOPS Web is a consumer of the Formix-owned API — not a separate integration effort. |
| N14 | Digital reporting sheets (replacing paper) | New capability. Awaiting Claire's template for existing paper reports. Cannot scope without that input. |
| N15 | Network-based scales | Confirmed aspirational. Serial RS232 is sufficient for MVP. Network scale support reduces hardware dependency but is not required for any current deployment. |
| S9 | Full localisation (per-user language from broader set) | Visual-first UI design helps operators with limited English. Full i18n (per-user language selection) is an incremental addition. Not blocking any current deployment. |

---

## Confirmed Removals (will not be built)

| Capability | Reason |
|---|---|
| Multi-mix compensation (adjust last mix for earlier deviations) | No one uses this. Confirmed by team. |
| Remote overrides (current implementation) | Not used by any customer. Conceptually replaced by ingredient substitution (N11, post-MVP). |
| Formix standalone stock management | Not needed — FOPS handles stock where deployed. Standalone sites don't need stock management from a weighing terminal. |

---

## Key Architectural Decisions Affecting MVP

| Decision | Impact on MVP |
|---|---|
| **Multi-tenant cloud** (AD.2) | Shared platform architecture; must support tenant isolation from day one |
| **Offline = order-level locking** (AD.3) | Orders locked to terminal when offline; manual admin override for conflicts. Simpler than merge/queue strategies but requires lock management. |
| **Formix owns the API** (AD.1) | No dependency on FOPS team. API is part of Formix scope — but API itself is should-have, not MVP. |
| **Managed rollout** (AD.4) | Deployment pipeline must support rollback to previous version. Affects CI/CD design from the start. |
| **Scale comms = continuous stream** (A.5) | Continuous stream with packet acknowledgement before label print. Not request-response. |
| **No pilot site** (BV.2) | MVP must be generalisable — cannot be tailored to one customer's workflow. |

---

## Risk Areas for MVP Delivery

| Risk | Severity | Mitigation |
|---|---|---|
| **Offline sync complexity** (H3) | High | Order-level locking reduces conflict surface. Admin override as escape hatch. Must test extensively with multi-terminal scenarios. |
| **Tolerance chain rounding** (H2) | Medium | Multi-step derivation from recipe % → order qty → mix size → container → tolerance band. Needs thorough edge-case testing across small/large orders. |
| **Sub-resolution weighing** (H2a) | Medium | Specified tolerance range (e.g. 0–5g). If essential, system insists on alternative weight base for accuracy. Edge case that needs clear UX. |
| **Allergen sequencing is new and complex** (N17) | High | No existing foundation to build on. Now MVP-essential so this risk cannot be deferred. Needs careful domain modelling early. |
| **Multi-hardware abstraction** | Medium | Three scale protocols (CSW, Rinstrun, Mettler), multiple printer formats (Fingerprint, ZPL, LDF/FDL). Abstraction layer needed early in development. |
| **Label rendering** | Medium | Single standard label format must be correctly interpreted and translated to multiple printer protocols. Must render allergen words in bold per legislation. |

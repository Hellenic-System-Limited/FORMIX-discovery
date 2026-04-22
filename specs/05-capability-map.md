# Capability and Dependency Map

> **Source:** Mob elaboration session — Step 2 output
> **Status:** Reviewed and corrected by team
> **Last updated:** 2026-04-15

---

## Core Capabilities

These are capabilities without which the system does not deliver its core value.

| # | The system can… | Source |
|---|---|---|
| C1 | Allow a planner to define recipes (ingredients + proportions by % or volume) | Groups 2, 4, N12 |
| C2 | Allow a planner to create orders (recipe + quantity) with system-calculated mix sizes | Group 2 |
| C3 | Present scheduled orders to operators, filtered by prep area (assigned at recipe level) | Group 2 |
| C4 | Guide an operator through step-by-step ingredient weighing for a mix | Group 2 |
| C5 | Read continuous weight stream from connected scale (sub-second, multiple hardware types; label print requires packet acknowledgement) | Groups 2, 5, 6 |
| C6 | Enforce weight tolerances with a hard block (no override for out-of-tolerance) | Group 2 |
| C7 | Capture source barcode from ingredient container (keyboard wedge input) | Groups 2, 5 |
| C8 | Capture lot number (manual) and batch number per weighing | Group 3 |
| C9 | Record each ingredient weighing as a transaction (core traceability artefact) | Group 3 |
| C10 | Run configurable per-ingredient QA checks during weighing | Group 2 |
| C11 | Run configurable end-of-mix QA checks per prep area | Group 2 |
| C12 | Print ingredient labels and mix labels to connected printers | Groups 3, 5 |
| C13 | Auto-advance to next scheduled mix on completion | Group 2 |
| C14 | Manage users with role-based access (operator, manager, QA, planner) | Groups 1, 5 |
| C15 | Operate offline with cached data, sync on reconnection | Groups 6, N8 |
| C16 | Store audit data for 5 years; temp data for 30 days | Group 6 |
| C17 | Run on-site or cloud-hosted | Group 6 |

## Supporting Capabilities

| # | The system can… | Source |
|---|---|---|
| S1 | Integrate with FOPS/FOPS Web for barcode verification, stock issues, and user auth via Formix-owned API | Groups 4, 5, BV.5 |
| S2 | Provide a generic API for ERP data sync (orders, recipes, ingredients, products) | N1 |
| S3 | Support ingredient substitution with one-time authorisation | N11 |
| S4 | Track per-batch costs (ingredient cost × weight) | Group 1 |
| S5 | Generate reports: transaction listing, order detail, ingredient usage, source audit, cost | Group 3 |
| S6 | Allow operators to switch prep area on a terminal | Group 8 |
| S7 | Support recipe process steps (non-ingredient, e.g. timed actions with countdown/lock) | N7 |
| S8 | Manage allergen data on ingredients, recipes, labels (words in bold = legislation), QA, and sequencing controls (run order, clean-between, scheduling) | N9, BV.7, BV.8 |
| S9 | Support localisation / visual-first UI for operators with limited English | Group 7 |
| S10 | Allow order amendment from terminal (with authorisation) | N5 |
| S11 | Specify 'use by' within recipe/ingredient management | N10 |

---

## Explicit Dependencies

| Dependency | Type | Required For |
|---|---|---|
| Scale hardware (CSW, Rinstrun, Mettler) | Hardware | C5 — continuous weight streaming with packet acknowledgement |
| Label printers (Honeywell Fingerprint, Zebra ZPL, LDF/FDL) | Hardware | C12 — label printing |
| Barcode scanners (keyboard wedge) | Hardware | C7 — source scanning |
| SQL database | Infrastructure | All data storage |
| Network (wired; optionally Wi-Fi) | Infrastructure | Multi-terminal, server comms |
| FOPS / FOPS Web (where deployed) | External system | S1 — stock/barcode/auth integration via Formix-owned API |

## Implicit Dependencies / Hidden Coupling

| # | Coupling | Risk | Status |
|---|---|---|---|
| H1 | ~~Prep area logic split between terminal and recipe~~ | ~~Incorrect filtering~~ | **Not a risk** — prep area assigned at recipe level; operators can switch terminal to alternative area |
| H2 | Tolerance calculation chain: recipe % → order qty → mix size → container allocation → per-weighing tolerance | Rounding errors, edge cases on small/large orders | ⚠️ Active risk |
| H2a | **Minimum registerable weight problem**: ingredient required quantity may be below scale resolution (e.g. 3g required vs 5g minimum readable weight) | Cannot accurately weigh; workflow blocked or inaccurate | ⚠️ **New — needs design decision** |
| H3 | Offline mode: two terminals could process the same order/mix simultaneously | Data conflict, double-weighing | ⚠️ Active risk |
| H4 | FOPS integration currently via shared DB — ~~moving to API requires FOPS to also change~~ | ~~Blocked if FOPS team can't deliver API~~ | **Resolved** — API is part of Formix scope; Formix owns the API layer |
| H5 | ~~Label format tied to printer model~~ | ~~Wrong format = unusable labels~~ | **Clarified** — labels are a standard format; software interprets design and renders to match specific printer protocol |
| H6 | ~~QA configurability unclear~~ | ~~May be hardcoded~~ | **Confirmed** — QA checks are fully configurable by design |

## Areas of High Complexity or Fragility

| Area | Why |
|---|---|
| **Offline sync** | Conflict resolution across multiple terminals, data consistency guarantees, queue management, order-level locking |
| **Tolerance + weighing edge cases** | Multi-step derivation chain from recipe % to actual tolerance band; plus minimum registerable weight problem where required amount is below scale resolution |
| **Multi-hardware abstraction** | Three scale protocols, three+ printer formats, all needing sub-second performance |
| **Allergen management (new)** | Cross-cuts recipes, ingredients, QA, labels, reporting — no existing foundation to build on |
| **Label rendering** | Single standard label format must be correctly interpreted and translated to multiple printer protocols (Honeywell Fingerprint, Zebra ZPL, LDF/FDL) |

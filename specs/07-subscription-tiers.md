# Subscription Tier Proposal

> **Source:** Mob elaboration session — commercial packaging discussion
> **Status:** Draft — awaiting team review
> **Last updated:** 2026-04-21

---

## Design Principles

1. **Legislation cannot be gated** — allergen words on labels are a legal requirement; every tier that prints labels must include them
2. **Value escalation** — each tier adds meaningful operational sophistication that justifies the price step
3. **Natural customer segmentation** — small single-site → mid-size multi-area → large multi-site/integrated

---

## Essentials — "Replace the spreadsheet / manual weighing"

*Target: Small sites, single prep area, basic weighing and traceability*

| Ref | Capability | Notes |
|---|---|---|
| C1 | Recipe management (% and volume, configurable tolerances) | |
| C2 | Order creation with auto-calculated mixes | |
| C4 | Step-by-step weighing guidance | |
| C5 | Continuous scale reading (RS232) | |
| C6 | Tolerance enforcement (hard block) | |
| C7 | Barcode scanning (keyboard wedge) | |
| C8 | Lot/batch number capture (optional) | |
| C9 | Transaction recording | Core traceability |
| C12 | Label printing (ingredient + mix labels, **allergen words in bold**) | **Legislation — cannot be gated** |
| C13 | Auto-advance to next mix | |
| C14 | User management — basic roles (operator, manager) | 2 roles only |
| C15 | Offline operation (order-level locking) | |
| N2 | Longer ingredient descriptions | Low effort constraint removal |
| N4 | Larger order numbers | Low effort constraint removal |
| N6 | Multiple units of measurement | |
| S8 | **Basic allergen data** — flag allergens on ingredients, render on labels | Legislation: labels must show allergens. No QA warnings or sequencing at this tier. |

**What Essentials does NOT include:** prep area filtering, configurable QA checks, RBAC beyond 2 roles, allergen QA/sequencing, reporting, API, order amendment.

---

## Professional — "Full production floor control"

*Target: Mid-size sites with multiple prep areas, QA requirements, compliance obligations*

Everything in **Essentials** plus:

| Ref | Capability | Why Professional |
|---|---|---|
| C3 | Orders filtered by prep area | Multi-area operations need this |
| S6 | Operator prep area switching | Goes with C3 |
| C10 | Per-ingredient QA checks (configurable) | Compliance-driven sites need QA |
| C11 | End-of-mix QA checks (configurable) | Compliance-driven sites need QA |
| C14+ | Full RBAC — operator, manager, **QA, planner** | 4 roles with granular permissions |
| S8+ | **Full allergen management** — QA warnings, allergen-aware validation | Beyond basic label rendering |
| N5/S10 | Order amendment from terminal (with authorisation) | Operational flexibility |
| S5 | Reporting (transaction listing, order detail, ingredient usage, cost) | Production visibility |
| N10/S11 | Use-by specification in recipe management | Quality-conscious sites |
| N11/S3 | Ingredient substitution with authorisation | Operational flexibility |
| S4 | Per-batch cost tracking | Cost visibility |

**What Professional does NOT include:** allergen sequencing/scheduling, API/ERP integration, recipe process steps, FOPS integration, managed rollout, recipe versioning.

---

## Enterprise — "Multi-site, integrated, fully compliant"

*Target: Large operations, 50+ terminals, FOPS integration, allergen-critical production*

Everything in **Professional** plus:

| Ref | Capability | Why Enterprise |
|---|---|---|
| N17 | **Allergen sequencing controls** — run order, clean-between, scheduling | Complex scheduling = enterprise need |
| S2/N1 | Formix-owned API for ERP/FOPS data sync | Integration = enterprise value |
| N13 | FOPS Web integration (as API consumer) | FOPS ecosystem |
| N3 | Auto-pull FOPS products as ingredients | FOPS ecosystem |
| N18 | Managed rollout with rollback | Large fleet management |
| N16 | Recipe versioning | Full audit trail for regulated industries |
| N7/S7 | Recipe process steps (timed actions, countdown) | Sophisticated recipe workflows |
| S9 | Full localisation (per-user language) | Multi-national workforce |
| N14 | Digital reporting sheets | Replace paper-based processes |
| N15 | Network-based scales (when available) | Infrastructure modernisation |
| C17+ | On-site hosting option | Some enterprise customers require it |

---

## Tier Boundary Summary

| Boundary | Logic |
|---|---|
| **Essentials → Professional** | **QA and compliance depth.** Essentials can weigh and print legal labels. Professional adds configurable QA checks, full allergen management, prep area control, and reporting. This is the "I need to prove compliance" upgrade. |
| **Professional → Enterprise** | **Scale, integration, and scheduling.** Enterprise adds the capabilities that only matter when you have many sites, need ERP integration, or run allergen-critical production lines that require sequencing. This is the "I need to connect and orchestrate" upgrade. |

---

## Allergen Capability by Tier

Allergen **words in bold on labels** are legislation — present in **all tiers**. The tiering is:

| Tier | Allergen Capability |
|---|---|
| Essentials | Allergen flags on ingredients → rendered in bold on labels |
| Professional | + allergen QA warnings during weighing, allergen-aware validation |
| Enterprise | + allergen sequencing (run order, clean-between, scheduling constraints) |

---

## Open Questions for Team Review

1. **Offline and data retention** — should these vary by tier?
   - Currently both are in Essentials (offline = order-level locking, retention = 5 years)
   - Option A: Essentials gets shorter retention (e.g. 1 year); Enterprise gets 5 years
   - Option B: Offline is a universal need for factory floor software and 5-year retention is a legal minimum — keep both universal
2. **Pricing model** — per terminal, per site, or per user? (out of scope for this doc but affects tier attractiveness)
3. **Tier naming** — are "Essentials / Professional / Enterprise" the right labels, or do we want something more domain-specific?
4. **Feature migration** — which Tier 2 (should-have) items from the MVP scope should be available from day one, and which are gated by subscription tier vs. delivery timeline?

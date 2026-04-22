# Domain Model

> **Source:** Mob elaboration session + codebase analysis
> **Status:** Validated — all model questions answered (2026-04-20)
> **Last updated:** 2026-04-20

---

## Entity Relationship Diagram (Text)

```
┌──────────────────────────────────────────────────────────┐
│                        PRODUCT                           │
│  A collection of recipes that together create something  │
│  Used to schedule a group of related orders              │
├──────────────────────────────────────────────────────────┤
│  description                                             │
│  mix_order (sequence of mixes)                           │
│  recipe_code ────────────────────────────────► RECIPE    │
│  ratio                                                   │
│  target_volume                                           │
└──────────┬───────────────────────────────────────────────┘
           │ 1 product schedules N orders (one per recipe)
           ▼
┌──────────────────────────────────────────────────────────┐
│                         ORDER                            │
│  "Make X kg of Recipe Y"                                 │
│  Created by planner; immutable once scheduled            │
│  System calculates number and size of mixes              │
├──────────────────────────────────────────────────────────┤
│  order_number (currently max 6 digits — constraint)      │
│  recipe_code ──────────────────────────────────► RECIPE  │
│  total_quantity                                          │
│  schedule_date                                           │
│  status                                                  │
└──────────┬───────────────────────────────────────────────┘
           │ 1 order contains 1..N mixes
           ▼
┌──────────────────────────────────────────────────────────┐
│                          MIX                             │
│  A single batch within an order                          │
│  Can span multiple physical containers                   │
├──────────────────────────────────────────────────────────┤
│  mix_number                                              │
│  target_weight (system-calculated)                       │
│  status (pending / in-progress / complete)               │
│  prep_area                                               │
│  qa_status                                               │
└──────────┬───────────────────────────────────────────────┘
           │ 1 mix uses 1..N containers
           │ 1 mix has 1..N transactions (one per ingredient weighing)
           ▼
┌──────────────────────────────────────────────────────────┐
│                      TRANSACTION                         │
│  One record per ingredient weighing                      │
│  Core traceability artefact                              │
├──────────────────────────────────────────────────────────┤
│  ingredient_code ────────────────────► INGREDIENT        │
│  actual_weight                                           │
│  source_barcode (scanned from supplier container)        │
│  lot_number (manual; supplier traceability; optional)    │
│  batch_number (internal; yield traceability; optional)   │
│  container_number                                        │
│  timestamp                                               │
│  user                                                    │
│  qa_responses                                            │
└──────────────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────────────┐
│                         RECIPE                           │
│  Defines ingredient proportions; rarely changes          │
│  Currently specified by % — volume to be added           │
├──────────────────────────────────────────────────────────┤
│  recipe_code                                             │
│  description                                             │
│  version (not currently supported; high-priority future)  │
└──────────┬───────────────────────────────────────────────┘
           │ 1 recipe has 1..N recipe lines
           ▼
┌──────────────────────────────────────────────────────────┐
│                      RECIPE LINE                         │
│  One ingredient (or process step — NEW) in a recipe      │
├──────────────────────────────────────────────────────────┤
│  line_number / sequence                                  │
│  line_type: INGREDIENT | PROCESS_STEP (new)              │
│  ingredient_code (if INGREDIENT)                         │
│  proportion_percent                                      │
│  proportion_volume (new — alternative specification)     │
│  unit_of_measure (new)                                   │
│  tolerance_low (configurable per line)                   │
│  tolerance_high (configurable per line)                  │
│  prep_area                                               │
│  -- For PROCESS_STEP --                                  │
│  step_description (new)                                  │
│  step_duration (new)                                     │
│  requires_terminal_lock (new)                            │
└──────────────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────────────┐
│                      INGREDIENT                          │
│  Master data for a weighable material                    │
├──────────────────────────────────────────────────────────┤
│  ingredient_code                                         │
│  description (currently limited — longer desc requested) │
│  allergens (new)                                         │
│  use_by_spec (new)                                       │
│  fops_product_code (where FOPS integration active)       │
│  unit_of_measure (new)                                   │
│  cost_per_unit (currently manual entry)                  │
└──────────────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────────────┐
│                       CONTAINER                          │
│  Physical vessel placed on scale                         │
│  New container triggered by weight capacity limit        │
│  OR recipe-defined split                                 │
├──────────────────────────────────────────────────────────┤
│  container_number (within a mix)                         │
│  tare_weight                                             │
│  max_weight_capacity (if capacity-based split)           │
└──────────────────────────────────────────────────────────┘


┌──────────────────────────────────────────────────────────┐
│                         USER                             │
│  System user with role-based access                      │
├──────────────────────────────────────────────────────────┤
│  username                                                │
│  role (operator / manager / qa / planner)                │
│  access_level                                            │
│  authentication_source (local / FOPS)                    │
│  preferred_language (per user — from broader set)         │
└──────────────────────────────────────────────────────────┘
```

## Relationship Summary

| From | To | Cardinality | Notes |
|---|---|---|---|
| Product | Order | 1 : N | One order per recipe in the product |
| Order | Recipe | N : 1 | Many orders can use the same recipe |
| Order | Mix | 1 : 1..N | System-calculated; one or many mixes per order |
| Mix | Container | 1 : 1..N | A mix can span multiple containers |
| Mix | Transaction | 1 : 1..N | One transaction per ingredient weighing |
| Recipe | Recipe Line | 1 : 1..N | Ordered sequence of ingredients and process steps |
| Recipe Line | Ingredient | N : 1 | (Only when line_type = INGREDIENT) |
| Transaction | Ingredient | N : 1 | Which ingredient was weighed |
| Transaction | User | N : 1 | Who performed the weighing |

## Labels (Output Artefacts)

| Label Type | Trigger | Contents | Attached To |
|---|---|---|---|
| Ingredient label | After each ingredient weighing accepted | Ingredient code, weight, batch no., lot no., order no., mix no., allergens in **bold words** (legislation) | Dependent on ingredient volume — varies |
| Mix label | On mix completion | Order no., mix no., recipe code/description, allergens in **bold words** (legislation) | Loop tag on dolav handle |

## Model Questions — All Answered ✅

- [x] **Product attributes**: mix order, recipe code, ratio, target volume, description
- [x] **Recipe versioning**: not currently supported; very high on nice-to-have list for traceability
- [x] **Prep area**: assigned at recipe level; terminal is switchable by operator
- [x] **Tolerances**: configurable per recipe line (5% is a common default, not a fixed rule)
- [x] **Lot and batch numbers**: remain optional — not all customers use them
- [x] **Ingredient label attachment**: dependent on ingredient volume; doesn't impact implementation as long as label is printed
- [x] **New container trigger**: weight capacity limit on container OR recipe-defined split
- [x] **Below-scale-resolution ingredients**: use specified tolerance (e.g. 0–5g); if essential, system insists on alternative weight base for accuracy

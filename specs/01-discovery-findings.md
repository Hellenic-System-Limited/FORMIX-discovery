# Discovery Findings

> **Source:** Mob elaboration session (reverse-engineering existing Formix/FOPS system)
> **Status:** Complete — all 8 discovery groups covered
> **Last updated:** 2026-04-15

---

## Group 1: Core User Goals and Business Outcomes

### Users

| User Role | Primary Activities |
|---|---|
| **Production Operator** | Step-by-step recipe execution at terminal; pressing buttons to progress through weighing workflow |
| **Production Manager** | Quantitative production oversight (mix counts), order scheduling, recipe creation and maintenance |
| **Quality Control** | In-line QA checks during production (per ingredient and per mix) |
| **Planner** | Creates orders days/weeks/months in advance |

### Core Business Outcomes

- Accurate recipe execution
- Full traceability (ingredient source → finished mix)
- Regulatory compliance
- Per-batch cost visibility

### Impact of System Unavailability

- Fallback to manual recipe management process — significant inefficiency and time loss
- Increase in human error
- Data and money lost due to inconsistencies and poor analytics/reporting
- Reputation impact from improper recipes
- Product recalls
- Unviable outputs for critical recipes

### Compliance Drivers

| Driver | Status |
|---|---|
| Traceability | Current requirement |
| Ingredient accuracy | Current requirement |
| Allergen management | **Future requirement** — not in existing system |

### Deployment Model

- Multi-user
- Multiple independent single-site installations (not centralised multi-site)

---

## Group 2: Primary User Journeys

### Operator Journey — Happy Path

```
PLANNER (days/weeks/months ahead)          OPERATOR (day of)
─────────────────────────────────          ─────────────────
Create order for Recipe X, Qty Y    ──►    Arrives → sees scheduled orders
  └─ system calculates mix sizes            │
                                            ▼
                                    Select order/recipe
                                            │
                                            ▼
                                    Mix number selected (usually auto)
                                            │
                                            ▼
                                 ┌──► Tare container
                                 │          │
                                 │          ▼
                                 │   Scan ingredient container
                                 │          │
                                 │          ▼
                                 │   Fill to tolerance (shown on screen)
                                 │   ⚠ HARD BLOCK if out of tolerance
                                 │          │
                                 │          ▼
                                 │   Per-ingredient QA
                                 │   (temp, other ingredients, allergens)
                                 │          │
                                 │          ▼
                                 │   Accept → print label if required
                                 │          │
                                 └──── More ingredients? ◄──┘
                                            │ No
                                            ▼
                                    End-of-mix QA checks
                                            │
                                            ▼
                                    Mix label printed
                                            │
                                            ▼
                                    Auto-advance to next scheduled mix
                                    (new container when instructed)
```

### Key Workflow Characteristics

| Aspect | Finding |
|---|---|
| Work trigger | Pre-scheduled orders; operators consume, not create |
| Prep area model | Terminals are area-specific (e.g. wet vs dry ingredients) |
| Weight capture | Both automatic (scale) and manual entry supported |
| Tolerance enforcement | **Hard block** — no workaround, no override for out-of-tolerance weights |
| Barcode scanning | Scans ingredient container/bag for source traceability |
| QA touchpoints | Per-ingredient AND end-of-mix, per prep area |
| Mix completion | Label printed, auto-advance to next scheduled mix |
| Recipe definition | Done within this system; recipes rarely change |
| Recipe specification | Currently by % of ingredient; desire to also support volume (new) |
| Order immutability | Scheduled orders cannot be altered once created |
| Order creation | Recipe + quantity → system calculates mix sizes |

---

## Group 3: Core Domain Concepts and Entities

### Entity Relationships

```
PRODUCT (collection of recipes)
  │
  └──► schedules multiple ORDERs (one per recipe in product)
          │
          │   ORDER = "Make X kg of Recipe Y"
          │   (created by planner, immutable once scheduled)
          │
          ├── RECIPE (defines ingredients by %)
          │     │
          │     └── INGREDIENT LINE (ingredient code + % proportion)
          │
          └── MIX 1..N (system-calculated batch sizes)
                │
                ├── CONTAINER 1..N (physical vessel on scale)
                │
                └── TRANSACTION (per ingredient weighing)
                      ├── ingredient code
                      ├── actual weight
                      ├── source barcode (supplier container)
                      ├── lot number (supplier traceability, manual entry, optional)
                      ├── batch number (internal traceability/yield, optional)
                      ├── order number + mix number
                      └── QA responses
```

### Entity Definitions

| Entity | Definition |
|---|---|
| **Product** | A grouping of recipes that together create something; used to schedule a collection of orders |
| **Recipe** | Defines ingredient proportions (currently by %); rarely changes |
| **Order** | "Make X kg of Recipe Y"; immutable once scheduled; system calculates mix count and sizes |
| **Mix** | A single batch within an order; can span multiple containers |
| **Container** | Physical vessel on the scale; new container when instructed by system |
| **Transaction** | One record per ingredient weighing; core traceability artefact |
| **Lot number** | From supplier packaging; typed manually; supplier traceability; currently optional |
| **Batch number** | Internal; used for yield and internal traceability; currently optional |
| **Source barcode** | Scanned from ingredient container/bag; audited |

### Labels

| Label Type | Contents | Physically Attached To |
|---|---|---|
| **Ingredient label** | Ingredient code, weight, batch no., lot no., order number, mix number. Allergens to be added. | _To be confirmed_ |
| **Mix label** | Order no., mix no., recipe code/description. Allergens to be added. | Loop tag on dolav handle |

### Reporting / Audit Artefacts

| Report | Purpose |
|---|---|
| Actual ingredient weights per order | Core traceability |
| Source barcode audit | Supplier traceability |
| Cost reporting | Per-batch costing (currently requires manual cost entry) |
| Order schedule | Planning visibility |
| Order detail | Execution detail |
| Ingredient listing | Master data |
| Ingredient usage | Consumption tracking |
| Ingredient assignment | Recipe composition |
| Transaction listing | Full weighing audit trail |

---

## Group 4: Key Capabilities

### Existing Capability Triage

| Capability | Current Status | MVP Relevance |
|---|---|---|
| Multi-mix compensation (adjust last mix for earlier deviations) | **No one uses this** | ❌ Drop |
| FOPS barcode verification | Active, needed | ✅ Basic API integration |
| FOPS issue/part-issue stock commands | Active, needed | ✅ Basic API integration |
| FOPS completed mix → stock | Active, needed | ⚠️ Only when FOPS present; not standalone MVP |
| FOPS user authentication | Active, needed | ✅ Basic API integration |
| Multiple scale types (CSW, Rinstrun, Mettler; serial + network) | Still a reality | ✅ Must support hardware variety |
| Remote overrides (current implementation) | Not used | ❌ Drop current implementation |
| One-time ingredient substitution authorisation | Not implemented, but important | ✅ **New requirement** (replaces remote overrides concept) |
| Ingredient cost tracking | Exists with manual cost entry | ⚠️ Defer improvement; keep basic structure |
| Formix-only stock management | Marginal standalone | ❌ Not MVP standalone |

### Deliberate Design Changes Identified

| Current Behaviour | Requested Change | Impact |
|---|---|---|
| Orders are immutable once scheduled | Allow amendment from terminal (with authorisation) | Workflow + authorisation model change |
| Recipes specified by % only | Support both % and volume | Recipe model change |
| No process steps in recipes | Add non-ingredient steps (e.g. "stir for X minutes") | **New entity type** in recipe model |

---

## Group 5: External Dependencies and Integrations

### Integration Landscape

| Dependency | Current State | Integration Method | MVP Implication |
|---|---|---|---|
| **FOPS** | Own product; active and needed | Shared DB tables / file-based comms | Need API abstraction layer; cannot assume direct DB access |
| **Scales** | Managed internally; CSW, Rinstrun, Mettler | Each model has its own protocol; serial + network | Scale adapter abstraction required; multiple protocol support |
| **Label printers** | Honeywell (Fingerprint) = current; Zebra (ZPL) = aspirational; LDF/FDL legacy | Multiple formats | Printer abstraction with pluggable format renderers |
| **Barcode scanners** | Keyboard wedge | Standard keyboard input | No special driver integration needed |
| **ERP systems** | None currently; desired (N1) | TBC | Generic sync API; keep ERP-agnostic |
| **User authentication** | Self-contained (own user table + optional FOPS users) | Direct | Self-contained for MVP |
| **Other** | None currently | — | Architecture should not preclude future integrations |

### ERP Data Sync Scope (New — N1)

| Direction | Data |
|---|---|
| Inbound (ERP → Formix) | Orders, recipes, ingredients, products |
| Outbound (Formix → ERP) | Orders, recipes, ingredients, products |
| Approach | Keep open/agnostic; no specific ERP commitment |

---

## Group 6: Operational Constraints

| Constraint | Requirement | Notes |
|---|---|---|
| **Scale-to-screen latency** | Sub-second | Real-time comms required |
| **System uptime** | 99%+ | ~3.6 days max downtime/year |
| **Terminals per site** | ~4 typical | Low per-site concurrency |
| **Total terminal capacity** | Up to 500 | Across entire customer estate |
| **Transaction volume** | ~500/day per site | Up to ~250K/day aggregate at full scale |
| **Audit data retention** | 5 years | Long-lived; must support historical queries |
| **Temp data retention** | 30 days | Clear lifecycle separation |
| **Network** | Wired standard; Wi-Fi nice-to-have | Must be reliable on wired; Wi-Fi adds variance |
| **Hosting model** | On-site network AND cloud-hosted | Dual deployment model — major architecture driver |
| **Terminal hardware** | PCs, industrial touchscreens, tablets, custom RPi + Windows | UI must work across screen sizes and input methods |
| **Offline support** | **Essential for MVP** | Infrequent but high-cost downtime on fast-moving lines |

### Critical Architecture Drivers

1. **Offline-first + cloud-or-on-prem hosting** = the single most impactful architectural constraint
2. **Sub-second scale latency** = real-time local processing required even in cloud-hosted mode
3. **500 terminal estate** = deployment, monitoring, and update strategy matters

---

## Group 7: Known Pain Points, Workarounds, and Limitations

| Pain Point | Who | Impact | Source |
|---|---|---|---|
| Outdated UI | All users | Barrier to adoption and efficiency | Internal |
| UX not intuitive | Operators | Training overhead; error-prone for new users | Internal |
| **Language barrier** | Operators | Very limited English skills; English-only system is an accessibility problem | Internal |
| No import/export capabilities | Managers / Planners | Manual effort; no ERP interop | Internal |
| Reporting requires spreadsheets | Managers | Data extracted and manipulated manually to be useful | Internal + Customer |
| **Site options crash** | Operators / IT | Assigning site options to mixers causes system crash; workaround = manually removing from config files; **unresolved for ~1.5 years** | Customer (Osvaldas) |
| **Windows 7 hardware** | IT / Operations | Current terminals running on Windows 7; need PC upgrades | Customer (Osvaldas) |
| **Manual allergen tracking** | QA / Technical | Allergen handling is entirely manual; want automated tracking and sequencing controls | Customer (Claire) |
| **Manual reporting sheets** | QA / Managers | Reporting done with manual paper sheets (e.g. daily mix tracking); no digital output | Customer (Claire) |

### Customer Feedback Status

- **First customer interview conducted** (2026-04-16) with site operators, technical, and IT staff
- **Strong change resistance**: operators have adapted to current system and strongly prefer not to change appearance or functionality; even minor changes are unpopular among long-term users
- Anecdotal internal feedback: **"don't remove functionality, improve styling and usability"**
- Recipe management pain points not yet covered — follow-up session planned with Claire (technical/seasoning knowledge)
- ⚠️ Further customer interviews still needed before finalising MVP scope

### Follow-Up Actions from Customer Interview

| Action | Owner | Status |
|---|---|---|
| Share manual reporting template (daily mix tracking) | Claire | ⏳ Pending |
| Follow-up session on recipe management pain points | Jamie + Claire | ⏳ To schedule |
| Invite Claire (technical) for seasoning/recipe insights | Ben | ⏳ Pending |

---

## Group 8: Legacy Behaviour

### Confirmed for Removal

| Capability | Reason |
|---|---|
| Multi-mix compensation | No one uses this |
| Remote overrides (current implementation) | Not used; replaced by N11 (ingredient substitution) |
| Formix standalone stock management | Not needed for standalone MVP |

### Confirmed Technology Changes

| Current | Target | Rationale |
|---|---|---|
| Pervasive/Btrieve database | SQL database | Modern, supportable, standard tooling. Customer confirmed (decision). |
| English-only UI | Localised / visual-first UI | Operator language barrier is a real accessibility problem |
| RS232 serial scales | Network-based scales (aspirational) | Customer (Rhys) suggested to reduce hardware dependency and ease cloud integration. Serial must still be supported. |

### Retained Behaviour

| Behaviour | Decision |
|---|---|
| Terminal-to-prep-area is configurable (operators can switch) | ✅ Retain — prep area is a terminal *setting*, not a hardware constraint |
| All existing core functionality | ✅ Retain — customer and internal feedback: do not remove features, improve UX |

### Customer Infrastructure Context

- This customer site has **highly resilient infrastructure**: frequent DB backups, VM snapshots, split data centres, multiple internet lines (reported by Rhys)
- Currently running **Windows 7** — PC upgrades desired

### No Further Unused Features Identified

Beyond the three items confirmed for removal, no additional unused features were identified. Further customer interviews may surface more.

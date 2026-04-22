# New Requirements Register

> **Source:** Mob elaboration session
> **Status:** Updated with mob session answers (2026-04-20)
> **Last updated:** 2026-04-20

---

## New Capabilities (Not in Existing System)

These requirements were explicitly stated during discovery as capabilities the existing system does **not** have.

| ID | Capability | Category | Complexity | Notes |
|---|---|---|---|---|
| **N1** | API in/out to sync data (e.g. recipes) with external ERP systems | Integration | High | Direction of data flow and ERP targets TBC |
| **N2** | Increased character limit for ingredient descriptions | Data model | Low | Currently constrained by legacy screen size and label width |
| **N3** | Auto-pull FOPS products as ingredients (where FOPS available) | Integration | Medium | Depends on FOPS API availability |
| **N4** | Larger order number capacity (remove 6-digit limit) | Data model | Low | Legacy database field size constraint |
| **N5** | Amend scheduled orders from terminal (with authorisation) | Workflow | Medium | **Contradicts current "immutable orders" rule** — deliberate change. Authorisation model needed. |
| **N6** | Handle varying units of measurement for ingredients/recipes | Domain logic | Medium | Impacts recipe definition, display, and weight calculation |
| **N7** | Process steps within recipe/mix (non-ingredient steps) | Workflow | High | **New entity type.** E.g. "stir for X minutes" with countdown/terminal lock. Introduces time-based workflow, not just weight-based. |
| **N8** | Offline support with cached data and reconnection sync | Architecture | **Very High** | Impacts every feature: data consistency, conflict resolution, queue management, user experience during disconnection |
| **N9** | Full allergen management | Compliance | High | Cross-cutting: recipes, ingredients, QA, labels, warnings, compliance reporting. **Allergen words on labels are legislation (must be bold)**. Icons are a nice-to-have (standardised set). Includes automated tracking + sequencing controls. |
| **N10** | Specify 'use by' within recipe management/specs | Domain logic | Medium | Affects ingredient validation during weighing; may interact with source barcode/FOPS data |
| **N11** | One-time ingredient substitution authorisation | Workflow | Medium | Replace/use alternative ingredient for a single mix with authorisation. Replaces unused "remote overrides" concept. |
| **N12** | Recipe specification by volume (not just percentage) | Domain logic | Medium | Alternative way to define recipe proportions; may coexist with percentage |
| **N13** | Integrate with FOPS Web (Factory Order Processing System) | Integration | Medium–High | Formix feeds data to FOPS Web via the Formix-owned API (same API as N1). Not a separate integration — FOPS Web is a consumer of the API. |
| **N14** | Replicate manual reporting sheets within system | Reporting | Medium | **Customer interview decision.** Currently done on paper (e.g. daily mix tracking). Claire to share template. |
| **N15** | Support network-based scales (replacing RS232) | Hardware | Medium | **Aspirational — not MVP.** Reduces hardware dependency; eases cloud/network integration. RS232 must still be supported. |
| **N16** | Recipe versioning | Domain logic | Medium | **Very high on nice-to-have list.** Currently recipes are edited in place. Version history needed for traceability (which version was used for a past order). |
| **N17** | Allergen sequencing controls | Compliance / Scheduling | High | Order of production runs, clean-between-runs rules, AND scheduling constraints. Part of allergen management (N9). |
| **N18** | Managed rollout with rollback for terminal updates | DevOps | Medium | Up to 500 terminals. Must support rollback to minimum one previous version. |

## Deliberate Design Changes (Behaviour That Should Change)

| Current Behaviour | Requested Change | Rationale |
|---|---|---|
| Orders immutable once scheduled | Allow terminal-based amendment with authorisation (N5) | Operational flexibility; reduce planner bottleneck |
| Recipes by percentage only | Support percentage OR volume (N12) | Different recipe types suit different specifications |
| Ingredient-only recipe lines | Add process steps with duration/countdown (N7) | Real production includes non-weighing steps |
| No allergen tracking | Full allergen lifecycle with sequencing controls (N9) | Regulatory direction and customer demand. Customer prefers words over icons on labels. |
| Manual ingredient cost entry | TBC — opportunity to automate via ERP/FOPS sync | Improve cost reporting accuracy |
| Ingredient description character limit | Remove/increase (N2) | Legacy screen/label constraint no longer applies |
| 6-digit order number limit | Remove (N4) | Legacy database field constraint |
| No Fox Web integration | Integrate Formix with FOPS Web via Formix-owned API (N13) | FOPS Web is a consumer of the same API (N1); avoid data duplication |
| Manual paper reporting sheets | Replicate in system as digital reports (N14) | Eliminate paper-based reporting workaround |

## Capabilities Confirmed for Removal

| Capability | Reason |
|---|---|
| Multi-mix compensation (adjust last mix for earlier deviations) | No one uses this |
| Remote overrides (current implementation) | Not used; replaced conceptually by N11 (ingredient substitution) |
| Formix standalone stock management | Not needed for MVP without FOPS |

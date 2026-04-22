# Open Questions and Assumptions

> **Source:** Mob elaboration session + codebase analysis
> **Status:** All questions answered (2026-04-20). Document retained as reference.
> **Last updated:** 2026-04-20

---

## Answered Discovery Questions

### Group 5: External Dependencies and Integrations ✅

| # | Question | Answer |
|---|---|---|
| 5.1 | FOPS — own or third-party? API or shared DB? | Own product; shared DB tables / file-based comms |
| 5.2 | Scale hardware — standardised protocol? | Each model has its own protocol; managed internally |
| 5.3 | Label printers in use? | Honeywell (Fingerprint) current; Zebra (ZPL) aspirational; LDF/FDL legacy |
| 5.4 | Barcode scanners? | Keyboard wedge — no special integration |
| 5.5 | Which ERPs? | Keep open/agnostic; sync = orders, recipes, ingredients, products |
| 5.6 | Authentication approach? | Self-contained user management |
| 5.7 | Other integrations? | None currently; architecture should not preclude future |

### Group 6: Operational Constraints ✅

| # | Question | Answer |
|---|---|---|
| 6.1 | Scale-to-screen latency? | Sub-second |
| 6.2 | Uptime requirement? | 99%+ |
| 6.3 | Terminals per site / total? | ~4 per site; support up to 500 total |
| 6.4 | Data volume / retention? | ~500 txn/day per site; 5 year audit; 30 day temp |

### Group 7: Pain Points ✅ (updated with customer interview 2026-04-16)

| # | Question | Answer |
|---|---|---|
| 7.1 | Operator frustrations? | Outdated UI, UX not intuitive, language barrier. **Customer adds:** strong change resistance — operators dislike even minor changes. Site options crash (1.5yr unresolved). Windows 7 hardware. |
| 7.2 | Workarounds? | Spreadsheets for reporting. **Customer adds:** manual reporting paper sheets for daily mix tracking (Claire to share template). Manual allergen tracking. Manual removal of site options from config files to avoid crash. |
| 7.3 | What breaks? | **Customer confirms:** site options assignment crashes system on mixers — persistent, unresolved 1.5 years. |

### Group 8: Legacy Behaviour ✅ (updated with customer interview 2026-04-16)

| # | Question | Answer |
|---|---|---|
| 8.1 | Behaviour no one would miss? | No additional items beyond already-identified removals. Customer reinforces: **do not remove functionality**. |
| 8.2 | Unused features? | None beyond multi-mix compensation and remote overrides |

---

## Remaining Open Questions

### Domain Model ✅ (answered 2026-04-20)

| # | Question | Answer |
|---|---|---|
| DM.1 | What attributes does **Product** carry? | Mix order, recipe code, ratio, target volume, description |
| DM.2 | Is there a concept of **recipe version**? | Not currently supported. **Very high on the nice-to-have list** for improved traceability. |
| DM.3 | How is **prep area** assigned? | At recipe level; terminal is switchable by operator |
| DM.4 | Are **tolerances** configurable or fixed at 5%? | **Configurable** per recipe line (5% is a common default, not a rule) |
| DM.5 | Should **lot and batch numbers** become mandatory? | **Remain optional** — not all customers use them |
| DM.6 | What does an **ingredient label** get attached to? | Dependent on volume of ingredient — doesn't impact implementation as long as a label is printed |
| DM.7 | When does the system instruct a **new container**? | Either a **weight capacity limit** on the container OR a **recipe-defined split** |
| DM.8 | How to handle **ingredient quantities below scale resolution**? | System uses the specified tolerance (e.g. 0–5g range). If essential, system insists on an **alternative weight base** for more accurate reading. |

### Architecture / Deployment ✅ (answered 2026-04-20)

| # | Question | Answer |
|---|---|---|
| AD.1 | What does the FOPS integration API look like? | A **proper API is part of Formix scope** — designed for reuse in other areas. Not FOPS's responsibility to provide one. |
| AD.2 | Cloud hosting model? | **Shared multi-tenant platform** |
| AD.3 | Offline data sync strategy? | **Order-level locking** in offline state; **manual admin override** ability for conflict resolution |
| AD.4 | How are updates deployed to 500 terminals? | **Managed rollout** with **rollback** capability — minimum of one previous version always available |

### Business / Validation ✅ (answered 2026-04-20)

| # | Question | Answer |
|---|---|---|
| BV.1 | Customer interview status? | First interview done (2026-04-16). Recipe management follow-up with Claire still needed. |
| BV.2 | Target customer or site for MVP pilot? | **No** — no specific pilot site selected |
| BV.3 | Languages for operator UI? | **Broader set, per user** — limited to customer need vs. business case justification |
| BV.4 | Data retention: 5 years or 1–3 years? | **5 years** confirmed as the requirement |
| BV.5 | What is "Fox Web"? | **FOPS Web** — the Factory Order Processing System web interface. Formix feeds data to it via the already-specified API. |
| BV.6 | Network scales: MVP or aspirational? | **Aspirational** — not required for MVP. Serial (RS232) is sufficient. |
| BV.7 | What does "allergen sequencing" mean? | **All of the suggested**: order of production runs, clean-between-runs rules, AND scheduling constraints |
| BV.8 | Allergen labels: words or icons? | **Words are legislation** — must be highlighted in **bold**. Icons are a nice-to-have (standardised set). |

---

## Assumptions — All Validated ✅

| # | Assumption | Result |
|---|---|---|
| A.1 | Each site is fully independent — no cross-site data sharing for MVP | ✅ **Confirmed** |
| A.2 | FOPS integration can be abstracted behind an API boundary | ✅ **Confirmed** — API is part of Formix scope |
| A.3 | Prep area filtering is a per-terminal configuration, operator-switchable | ✅ **Confirmed** |
| A.4 | QA questions/checks are configurable per recipe or ingredient, not hardcoded | ✅ **Confirmed** |
| A.5 | Scale communication is continuous streaming | ✅ **Confirmed** — continuous stream, but requires **acknowledgement of last packet** before label can be printed |
| A.6 | Label content and format should be configurable, not fixed | ✅ **Confirmed** — configurable per site |
| A.7 | ~~Offline support is post-MVP~~ | ❌ **Overridden** — offline is MVP-essential

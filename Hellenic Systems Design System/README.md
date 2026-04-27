# Hellenic Systems — Design System

> **Built around you.** — the design system for Hellenic Systems, a UK‑based specialist in computer systems for food & manufacturing since 1988.

This folder is a **working design system**: tokens, typography, colours, logos, iconography guidance, and a UI kit that recreates Hellenic's flagship Formix/FOPS Recipe System terminal. It exists so design agents, engineers, and marketers can produce on‑brand interfaces, decks, and prototypes without reinventing the wheel.

---

## Sources consulted

| Source | Type | Used for |
|---|---|---|
| `uploads/Hellenic Brand Guidelines v2.pdf` (→ `uploads/brand-guidelines.txt`) | Brand PDF | Logo rules, colour palette (hex/RGB/CMYK), typography (Figtree), tone of voice, messaging pillars, gradient proportions |
| `Hellenic.FOPS.RecipeSystem-main/` (local mount, read‑only) | Codebase (Delphi 7 + legacy Free Pascal) | Product vocabulary, screen flows, terminal UI structure, iconography (arrows, recipe icon), colour conventions (the legacy `16776176` = `#FFFDF0` cream page background, `clBlue` field text) |
| `Hellenic.FOPS.RecipeSystem-main/specs/*.md` | MVP specs | Domain model, user roles, capability map, MVP scope — shaped the UI kit screen choice |

---

## Index of files (root)

| Path | Purpose |
|---|---|
| `README.md` | You're reading it |
| `SKILL.md` | Agent‑Skill entry point — load this to act as a Hellenic designer |
| `colors_and_type.css` | CSS custom properties + semantic type classes |
| `assets/` | Logos (colour & white), mark, legacy `.ico` files |
| `preview/` | Per‑token cards surfaced in the Design System tab |
| `ui_kits/formix-terminal/` | React UI kit recreating the Formix Recipe System terminal |

---

## Company snapshot

At **Hellenic Systems** we design and manufacture specialist computer systems for food & manufacturing. Trusted by **130+ companies across the UK and Europe** since **1988**. We blend standardised modules with bespoke system design — *a perfect fit for every customer*.

**Messaging pillars** (verbatim from the brand book):

- **Reliability** — Software you can count on, day in, day out.
- **Innovation** — Always evolving to meet tomorrow's challenges.
- **Customisation** — Tailored systems built around you.
- **Traceability** — Full visibility of your processes from start to finish.
- **Expert support** — UK‑based team with proven industry knowledge.

---

## CONTENT FUNDAMENTALS

**Tone:** clear, confident, approachable. We're experts but keep things simple.

### The rules
- **Plain English.** Complex ideas, simple language. No jargon unless we define it.
- **First person.** We say **"we"** and **"you"** — never "the customer", "users", or "the system" when "you" or "we" will do.
- **Audience‑tuned.** More direct and concise for technical users; more conversational for general comms. Same voice, different register.
- **British English.** `colour`, `customise`, `optimise`, `realise`. Always.
- **Title case for product names** (Formix, FOPS, Recipe System). **Sentence case** for UI labels and headings ("Order details", not "Order Details").
- **No emoji** in product, marketing, or technical docs. The brand leans confident/professional; emoji is off‑brand. (Legacy Delphi UI uses none.)
- **No unicode decoration** (arrows like → are fine inline; avoid bullets like ✦ ◆ ★).
- **Numerals:** numbers one to nine in prose ("nine terminals"); **digits for specs, weights, counts, and UI** ("130+ companies", "Scale 1", "50.00 kg").

### Key phrases we reuse
- **"Built around you."** — the north‑star strapline.
- "Empowering food and manufacturing innovators with smart, scalable technology — designed for today, built for tomorrow."
- "Delivering complete traceability throughout your manufacturing operation."
- "We believe every manufacturer deserves technology that adapts to their processes — not the other way around."

### Do / don't — examples
| ✅ Do | ❌ Don't |
|---|---|
| "Weigh the next ingredient." | "The operator shall proceed to weigh the next ingredient." |
| "Your order is locked to this terminal while you're offline." | "Order is currently in an exclusive-lock state due to offline mode." |
| "We'll calculate the mix sizes for you." | "The system will compute optimal mix sizing." |
| "Out of tolerance — re‑check the weight." | "⚠️ ERROR: weight outside acceptable tolerance range ⚠️" |

### Casing cheatsheet
- Buttons: **Sentence case** — `Start order`, `Print label`, `Confirm mix`.
- Headings/titles: **Sentence case** — `Recipe orders`, `Scale setup`.
- Product & proper nouns: **Title/brand case** — `Hellenic Systems`, `Formix`, `FOPS`, `Recipe System`.
- Status words in tables: **lower‑case** unless proper — `in progress`, `complete`, `on hold`.

---

## VISUAL FOUNDATIONS

### Colour
Three brand colours, anchored by white. **60 / 30 / 10** rule:
- **60% white** — dominant canvas. Hellenic is *not* a dark‑UI brand.
- **30% midnight or purple** — structural chrome, text, primary surfaces.
- **10% pink** — reserved for calls to action and moments of impact. Never decorative.

Exact values (from the brand book):
- `#122559` Midnight — CMYK 100/90/38/28, RGB 18/37/89
- `#4934ad` Purple — CMYK 87/82/0/0, RGB 73/52/173
- `#d4245c` Pink — CMYK 10/95/41/2, RGB 212/36/92

**Gradient.** The signature Hellenic gradient is dark blue ~45% → purple ~35% → pink ~20%. Used as a *design feature*, not a background wash under text. Showpiece moments only — hero units, gradient outlines on key cards, fills on the brand mark.

### Typography
**Figtree.** Full stop. **Regular (400)** for body, **SemiBold (600)** for titles and highlighted text. A single family covers headlines through captions — crisp geometric sans that reads well on industrial touchscreens and marketing pages alike.

Scale: 12 / 14 / 16 / 18 / 22 / 28 / 36 / 48 / 64 px, 1.25 modular. Tight letter‑spacing (`-0.01em` to `-0.02em`) on large display text. All‑caps eyebrows at 12 px with `0.08em` tracking.

Body text uses `line-height: 1.5`. Display text `1.1`. **Never set display smaller than 28 px** in product UI; touchscreen operators need size.

### Backgrounds
- **White‑dominant.** Pages are `#ffffff` or the off‑white `--hs-bg-alt: #f6f7fb`.
- **No hand‑drawn illustration.** The brand has none.
- **No repeating patterns or textures.**
- **No photography overlays** (the brand book shows none; keep imagery plain until source photos are supplied).
- **Gradient usage:** only as a *feature* — one hero band, mark fill, or a thin top‑border accent. Never a full‑bleed background under body text.

### Animation
- **Short, purposeful.** `120ms` (fast), `200ms` (base), `320ms` (slow). Everything else is wrong.
- **Ease:** `cubic-bezier(0.2, 0.7, 0.2, 1)` default; `cubic-bezier(0.16, 1, 0.3, 1)` for entrance. No bouncy springs. No elasticity. This is industrial software.
- **Fades + 4‑8 px translate** for enters/exits. No scale pops.

### Interaction states
- **Hover:** background shifts one step deeper on solid buttons; borders darken on outlines. Never opacity hover — it looks amateur on light UIs.
  - Primary button: `#122559` → `#0e1d46`.
  - Pink CTA: `#d4245c` → `#b31a4c`.
- **Press:** `translateY(1px)` + shadow drops from `md` → `sm`. No scale.
- **Focus:** 3 px `rgba(73, 52, 173, 0.25)` ring — purple, 25% alpha. Always visible for keyboard.
- **Disabled:** 40% alpha + `cursor: not-allowed`. No greyscale.

### Borders & dividers
- **1 px solid** at `--hs-border` (`#dde1ec`) for most separation.
- **2 px** only when marking a selected/active row on touchscreen terminals.
- Do not use left-border accent cards.

### Shadow system (rooted in midnight, not black)
```
xs: 0 1px 2px  rgba(18,37,89,.06)
sm: 0 2px 6px  rgba(18,37,89,.08)
md: 0 6px 20px rgba(18,37,89,.10) + 1px 3px .06  ← default card
lg: 0 20px 45px rgba(18,37,89,.14) + 4px 10px .06 ← modals/menus
```
Shadows use **midnight tint**, not pure black. Keeps the light UI feeling on‑brand rather than flat grey.

### Radii
- `4 / 6 / 10 / 14 / 20 / 999px`
- **Default card & button: 10 px.**
- Pills (999 px) for status chips only.

### Cards
- White background, 1 px `#dde1ec` border, `shadow-md`, `radius-md (10 px)`, `padding-6 (24 px)`.
- **No gradient backgrounds on content cards.** Gradient is reserved for hero / brand moments.
- **No left‑border accent stripe.** (Off‑brand and AI‑slop‑coded.)
- Hover lift: `shadow-md` → `shadow-lg`, `translateY(-2px)`.

### Layout & density
- **Marketing:** generous — max content width `1120 px`, `80–120 px` vertical section rhythm.
- **Product / terminal UI:** dense, information-first — the Formix terminal packs order details, ingredient, scale, and action buttons into `800×600`. Respect this: industrial operators need everything on one screen, **no scrolling**.
- Touch targets: **44 px minimum** in the terminal (matches legacy Delphi button heights).

### Transparency & blur
- **Rarely.** One approved use: 10% transparency on the icon mark as a watermark across collaterals (per brand book).
- No frosted‑glass, no `backdrop-filter` product UI.

### Imagery tone
- When we commission or source imagery: **warm, human, shop‑floor**. Manufacturing lines, ingredients, people in hi‑vis. Never stock‑tech gradients, never abstract circuitry.
- Colour grade: slightly cool, neutral — so it sits alongside the midnight‑dominant palette without clashing.

---

## ICONOGRAPHY

### What's in the legacy product
The Delphi terminal ships with **bitmap arrow glyphs** — Blue Up / Down / Left / Right (and green variants) at 24×24 and 118×52 — used as navigation and action buttons. There is no icon *font* and no SVG set. Icons in the UI kit are **outline strokes, 1.75 px weight, square caps**, matching the flat industrial feel of the legacy arrows.

`assets/legacy/Recipe.ico` and `assets/legacy/IniEditor.ico` are the original Delphi application icons — kept for fidelity when recreating the terminal look.

### What we use going forward
- **Lucide** icons (CDN: `https://unpkg.com/lucide@latest`) as the default icon set. **Flagged substitution** — the brand book doesn't specify a system. Lucide was chosen for: matching stroke weight to the legacy arrow glyphs, excellent industrial/manufacturing coverage (scale, package, clipboard‑check, barcode), and free MIT licence.
- **Stroke weight:** 1.75 px at 24 px, 2 px at 20 px. Never filled except for status dots.
- **Size:** 16 / 20 / 24 px.
- **Colour:** `currentColor` — icons inherit text colour. Never coloured independently.

### Emoji
**No.** Not in product, not in marketing, not in decks. The brand is confident/professional.

### Unicode as icons
Only `→` (arrow) and `·` (middle dot, as a separator) are acceptable inline. Nothing else.

### When an icon doesn't exist
Use a labelled placeholder box (`1 px dashed border, caption text`). Never hand‑roll a replacement SVG — ship the placeholder, flag it, ask.

---

## Products represented

1. **Formix / FOPS Recipe System** — a Windows Delphi terminal for industrial recipe weighing. Operators step through a recipe at a scale terminal, weighing each ingredient, scanning source barcodes, passing QA checks, and printing ingredient + mix labels. MVP modernisation is planned (SQL DB, multi‑tenant cloud, visual‑first UI for operators with limited English).
   - See `ui_kits/formix-terminal/` for the UI kit recreation.

No marketing website source was provided, so **no marketing UI kit has been built**. Ask to add one if you want it.

---

## Caveats

- Logos are the **official transparent PNGs** provided by the brand owner: `assets/hellenic-logo.png` (full colour) and `assets/hellenic-logo-white.png` (white). `assets/hellenic-mark.png` is the "H" icon, auto-cropped from the full-colour file.
- **Figtree** is loaded from brand-supplied TTFs in `fonts/` — full weight range (Light 300 → Black 900) plus matching italics.
- The Delphi codebase's UI conventions (cream page bg `#FFFDF0`, blue field text, Tahoma fallback) are documented but the **modernised UI kit uses the brand system**, not the legacy look. If you want a fidelity recreation of the *current* terminal, that's a separate ask.
- Lucide icons are a flagged substitution — no icon system was specified in the brand book.

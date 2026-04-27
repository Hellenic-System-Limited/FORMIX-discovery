---
name: hellenic-design
description: Use this skill to generate well-branded interfaces and assets for Hellenic Systems (UK specialist in food & manufacturing computer systems, est. 1988), either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colours, type, fonts, assets, and a UI kit for the flagship Formix/FOPS Recipe System terminal.
user-invocable: true
---

Read the `README.md` file within this skill, and explore the other available files. The key rules:

- **Voice:** plain English, "we/you", sentence case, British spelling, no emoji.
- **Palette:** midnight `#122559`, purple `#4934ad`, pink `#d4245c` (CTA only, 10%). White-dominant surfaces (60%). Use `colors_and_type.css`.
- **Type:** Figtree. Regular for body, SemiBold for titles. Never smaller than 28 px for display in product UI.
- **Gradient:** 45 / 35 / 20 midnight → purple → pink. Feature use only, never under body text.
- **Shadows:** midnight-tinted, not black.
- **Icons:** Lucide, 1.75 stroke, `currentColor`. No emoji.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out of `assets/` and create static HTML files for the user to view, importing `colors_and_type.css`. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

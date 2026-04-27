# Formix Terminal — UI Kit

A React (inline JSX + Babel) recreation of the Hellenic **Formix/FOPS Recipe System** terminal — modernised onto the current Hellenic brand system (Figtree, midnight/purple/pink, white-dominant surfaces) while keeping the structural flow of the legacy Delphi app.

The legacy app is a fixed `800×600` terminal running on industrial touchscreens. This kit respects the same canvas size so an operator flow feels the same shape, but applies today's brand.

## Screens (click-thru)

1. **Login** — operator name + PIN, terminal label in the header.
2. **Main menu** — the four action tiles (Recipe orders, Setup, Transactions, View mix).
3. **Process recipe** — the core weighing screen: order details, current ingredient, live scale reading, tolerance band, action buttons.
4. **Mix complete** — QA confirmation + label print.

`index.html` wires them together as a demo. Components are split into per-file JSX.

## Files

- `index.html` — entry, Babel, routes the four screens.
- `App.jsx` — top-level state machine.
- `Shell.jsx` — the `800×600` terminal chrome (header, footer, clock).
- `LoginScreen.jsx`, `MainMenuScreen.jsx`, `ProcessRecipeScreen.jsx`, `MixCompleteScreen.jsx`.
- `ui.jsx` — shared `Button`, `Field`, `Chip`, `ScaleReadout`, `ToleranceBar`.

## Source fidelity

Screens are lifted from the Delphi `.dfm` definitions:
- `ufrmFormixLogin.dfm` → `LoginScreen`
- `ufrmMainMenu.dfm` → `MainMenuScreen` (four action panels on a cream field)
- `ufrmFormixProcessRecipe.dfm` → `ProcessRecipeScreen` (order panel + mix details + large weight readout + "Mix Completion" label)

The copy is rewritten to match the brand voice (plain English, "we/you", sentence case), not the legacy strings.

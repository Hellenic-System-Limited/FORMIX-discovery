# Hellenic Recipe Management Admin App — Interactive Prototype

This is an interactive prototype for the Hellenic Recipe Management Admin App, built using the Hellenic Design System. It is structured for future backend integration.

## Features
- **Recipe Management**: View, create, edit, and manage recipes, lines, tolerances, allergens, and process steps.
- **Order Management**: View, create, and manage production orders. Assign recipes, schedule mixes, and track status.
- **Ingredient Management**: View, create, and manage ingredients, allergens, costs, and units of measure.
- **User & Role Management**: View, create, and manage users, assign roles, and set access levels.
- **Audit & Traceability**: View transaction logs, search/filter by order, ingredient, user, or date.

## Tech Stack
- React 18 (JSX, Babel in-browser for prototype)
- Hellenic Design System CSS and UI primitives

## Structure
- `App.jsx` — Main app entry and navigation
- `Shell.jsx` — App shell and header
- `Nav.jsx` — Sidebar navigation
- `RecipeAdmin.jsx`, `OrderAdmin.jsx`, `IngredientAdmin.jsx`, `UserAdmin.jsx`, `AuditAdmin.jsx` — Section screens

## Future Integration
- Designed for easy replacement of mock data with real API calls
- Modular components for CRUD, list, and detail views

---
For design system details, see the parent folder and `colors_and_type.css`.

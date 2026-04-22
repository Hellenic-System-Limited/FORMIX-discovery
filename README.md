# Hellenic FOPS Recipe System

This repository contains source code and assets for the Hellenic Formix/FOPS Recipe System, an industrial recipe weighing and terminal workflow application used in production environments.

The solution includes:

- A Windows Delphi GUI application (primary terminal app).
- A legacy Free Pascal codebase (historical/parallel implementation and conversion tooling).
- SQL scripts and data conversion assets.
- Operational assets such as scale label formats and terminal INI examples.

## Table of Contents

1. [Solution Overview](#solution-overview)
2. [Repository Layout](#repository-layout)
3. [Technology Stack](#technology-stack)
4. [External Dependencies](#external-dependencies)
5. [Build Instructions (Delphi)](#build-instructions-delphi)
6. [Build Instructions (Legacy Pascal)](#build-instructions-legacy-pascal)
7. [Runtime Configuration](#runtime-configuration)
8. [Database and Data Files](#database-and-data-files)
9. [Running the Application](#running-the-application)
10. [Troubleshooting](#troubleshooting)
11. [Known Gaps in This Repository](#known-gaps-in-this-repository)
12. [Maintenance Notes](#maintenance-notes)

## Solution Overview

The main application is the Delphi terminal client started from `Source/Delphi/SFormix.dpr`.

At startup it:

1. Initializes the application and main menu UI.
2. Reads terminal identity from command-line argument 1 (for example `Scale1`).
3. Loads configuration values from INI and database-backed registry tables.
4. Creates FORMIX and optional FOPS database modules.
5. Opens recipe/order workflows with weighing, barcode, lot/batch, printing, and optional QA checks.

Relevant startup/source files:

- `Source/Delphi/SFormix.dpr`
- `Source/Delphi/ufrmMainMenu.pas`
- `Source/Delphi/udmFormix.pas`
- `Source/Delphi/Database/udmFormixBase.pas`
- `Source/Delphi/uIni.pas`

## Repository Layout

Top-level folders of interest:

- `Source/Delphi/`
  - Main Windows terminal application and tools.
  - Includes `SFormix.dpr` (primary app) and `IniEditor.dpr` (INI editor utility).
  - Contains `Database/` modules and `SQL/` scripts.
- `Source/Pascal/`
  - Legacy Free Pascal codebase and historical conversion/build scripts.
- `aws-aidlc-rule-details/`
  - AI-DLC documentation/rules currently stored in this repo; not runtime dependencies for the recipe application.

Additional Delphi subfolders include assets such as `FlowCharts/`, `RinstrunSimulator/`, `AnalogMetre/`, and printer format files (`*.FDL`, `*.LDF`, `*.LAB`).

## Technology Stack

Primary (Windows terminal app):

- Borland Delphi 7 project format (`.dpr`, `.dof`, `.cfg`, `.dfm`, `.pas`).
- VCL desktop UI.
- Pervasive/Btrieve style data access components and related libraries.

Legacy/alternate:

- Free Pascal build scripts (`compfrmx.bat`, `FPNODEF.CFG`).
- Historical Formix terminal program sources in `Source/Pascal/`.

## External Dependencies

This repo references proprietary and local libraries that are not fully included here.

Examples from project and uses clauses:

- Relative source dependencies such as `..\..\HSLLIBW\...`.
- Delphi packages listed in `SFormix.dof` (for example Rx, Btrieve, custom HSL/Fops packages).
- Units such as `uIniUtils`, `uDatabaseDetails`, `udmDatabaseModule`, and other framework/common modules expected from shared internal libraries.

Because of this, a clean clone may not compile until private dependencies are restored on expected paths.

## Build Instructions (Delphi)

### Prerequisites

1. Windows development machine.
2. Borland Delphi 7 installed.
3. Required third-party/internal packages installed and available to Delphi.
4. Internal shared libraries restored (notably HSLLIBW and related units/components).

### Build Steps

1. Open `Source/Delphi/SFormix.dpr` in Delphi 7.
2. Verify search paths and package references from `Source/Delphi/SFormix.dof` / `Source/Delphi/SFormix.cfg`.
3. Resolve any missing units/packages by restoring local dependency folders.
4. Build the project to produce `SFormix.exe`.

Optional utility:

- Open and build `Source/Delphi/IniEditor.dpr` to produce the INI editor tool.

## Build Instructions (Legacy Pascal)

The `Source/Pascal/` tree contains a legacy Free Pascal build path.

The script `Source/Pascal/compfrmx.bat` demonstrates expected compiler/toolchain versions and defines:

- FPC 2.6.0 and 2.0.0 paths.
- External include/unit path rooted at `\hsllib`.
- Customer-specific define passed as `%1`.

Example invocation (from a suitable legacy environment):

```bat
compfrmx.bat CUSTOMER_DEFINE
```

Use this path only if you maintain the legacy Pascal implementation; the Delphi app is the primary modern Windows UI in this repo.

## Runtime Configuration

### Command-Line Terminal Name

The terminal identifier is read from argument 1 at startup.

Example:

```bat
SFormix.exe Scale1
```

The terminal name is used to scope settings (for example folder names such as `Scale.Scale1` in the registry/settings table logic).

### INI Configuration

`uIni.pas` reads key values from an application INI object, including:

- Section `[Database]`
  - `DatabaseName` (default `FORMIX`)
  - `ServerName`
  - `FopsDatabaseName` (default `FOPS`)
  - `FopsServerName`
  - `QAServiceURL`
- Section `[Main]`
  - `UseFopsUsers` (boolean)

Example baseline INI:

```ini
[Main]
UseFopsUsers=false

[Database]
DatabaseName=FORMIX
ServerName=
FopsDatabaseName=FOPS
FopsServerName=
QAServiceURL=
```

Terminal-specific sample INI files are also present, such as `Source/Delphi/Term61.INI`.

### Database-Backed Terminal Settings

Many runtime options are read from a registry/settings table via `udmFormixBase` (for example scale setup, barcode rules, issue-to-stock behavior, lot/batch prompts, QA flags, and printing behavior).

SQL helpers in `Source/Delphi/SQL/` include examples for enabling options such as `SFXModeIssue` and NAV barcode settings.

## Database and Data Files

The system expects FORMIX and (optionally) FOPS database connectivity.

From code behavior:

- FORMIX connection is required for core operation.
- FOPS connection is conditionally required depending on settings (for example when `UseFopsUsers` or FOPS issue/stock options are enabled).

Schema/data evolution scripts are under `Source/Delphi/SQL/`, including:

- `formix_conversion_8_0_3_0.SQL`
- `LOTIREF.SQL`
- `SourceWarnings.sql`
- `SQL.txt` (table creation examples such as `UserTable` and `StockTable`)

Some conversion guidance/history is embedded in source comments (for example version notes in `Source/Delphi/uModCtv.pas`).

## Running the Application

1. Ensure database servers are reachable and credentials/config are valid.
2. Ensure required INI values are present.
3. Start the executable with a terminal name argument:

```bat
SFormix.exe Scale1
```

4. Log in and use the main menu to access recipe orders and processing workflows.

If startup detects incompatible configuration (for example FOPS-required settings with no FOPS DB connection), the application will terminate by design.

## Troubleshooting

### Build fails with missing units or packages

Cause:

- Missing internal/shared libraries or third-party Delphi packages.

Actions:

1. Restore expected shared source trees (for example HSLLIBW) to relative paths used by the project.
2. Install required Delphi component packages referenced in `SFormix.dof`.
3. Re-check Delphi search paths and package paths.

### Runtime cannot connect to FORMIX/FOPS

Actions:

1. Verify INI `[Database]` values.
2. Verify server/database availability and client drivers.
3. Temporarily disable FOPS-dependent runtime settings if FOPS DB is unavailable.

### Terminal-specific behavior looks wrong

Actions:

1. Confirm startup argument (terminal name) is correct.
2. Confirm corresponding `Scale.<TerminalName>` settings in registry/settings table.
3. Review related terminal INI files and scale setup values.

## Known Gaps in This Repository

The following are likely required but not fully included:

- Internal/proprietary shared libraries and components referenced by relative paths.
- Complete environment setup steps for customer/site deployment.
- A modern automated test harness.

This README therefore documents the observed solution structure and behavior from available source, but some environment-specific build/run details remain organization-specific.

## Maintenance Notes

- Keep operational SQL scripts in `Source/Delphi/SQL/` under version control with change notes.
- Preserve terminal-name startup convention to avoid breaking per-terminal configuration resolution.
- When adding settings, keep defaults and descriptions aligned in `LoadRxmTermRegSettings` (`udmFormixBase`).
- For new deployments, document site-specific INI/database values in environment-specific docs (not committed secrets).

---

If you want, this README can be extended with a deployment playbook section (service accounts, workstation setup checklist, and go-live validation script) once your target environment details are available.
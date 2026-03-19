# AGENTS.md - WRunner Project Guide

## Project Overview

WRunner is a **Rofi-like application launcher for Windows**, written in Object Pascal (Delphi 12 / RAD Studio). It uses the VCL (Visual Component Library) framework and targets Win32/Win64 platforms.

## Build Commands

The project uses **Embarcadero MSBuild** via `src/wrunner.dproj`.

```bash
# Debug build (Win64, default)
msbuild src\wrunner.dproj /p:Config=Debug /p:Platform=Win64

# Release build (Win64)
msbuild src\wrunner.dproj /p:Config=Release /p:Platform=Win64

# Win32 build
msbuild src\wrunner.dproj /p:Config=Debug /p:Platform=Win32

# Full rebuild (clean + build)
msbuild src\wrunner.dproj /t:Rebuild /p:Config=Debug /p:Platform=Win64
```

**Output directories:**
- Debug: `bin/debug/64bit/`, DCU: `dcu/debug/64bit/`
- Release: `bin/release/64bit/`, DCU: `dcu/release/64bit/`

## Testing

No testing framework is currently configured. The `tests/` directory is empty. When adding tests, consider using **DUnitX** (the modern Delphi test framework) and document the test runner command here.

## Linting & Type Checking

No static analysis or linting tools are currently configured. If added (e.g., Pascal Analyzer, FixInsight), document commands here.

The Delphi compiler itself performs strict type checking at build time. Always verify changes compile cleanly in both Debug and Release configurations.

## Project Structure

```
src/
  wrunner.dpr              # Program entry point
  wrunner.dproj            # Delphi project file (MSBuild)
  forms/
    Main.pas / .dfm        # System tray main form (TMainForm)
    WRunnerFrm.pas / .dfm  # Launcher UI form (TWRunnerForm)
  classes/
    WRunner.Apps.Entities.pas  # Desktop entity data model
    WRunner.Apps.Loader.pas    # App loading (stub)
    WRunner.Results.pas        # Results handling (stub)
bin/                       # Compiled binaries (gitignored)
dcu/                       # Compiled DCU files (gitignored)
tests/                     # Tests (currently empty)
```

## Code Style Guidelines

### Naming Conventions

- **Types (classes, records):** PascalCase with `T` prefix → `TDesktopEntity`, `TWRunnerForm`
- **Fields/variables:** PascalCase with `F` prefix for private fields → `FDisplayName`, `FRunner`
- **Properties:** PascalCase, no prefix → `DisplayName`, `ParsingName`
- **Methods:** PascalCase → `LoadApplications`, `ApplyTheme`
- **Parameters:** PascalCase, no prefix → `const AValue: string`
- **Constants:** PascalCase or UPPER_SNAKE → `DefaultTimeout`
- **Unit names:** Dot-separated namespace → `WRunner.Apps.Entities`, `WRunner.Forms.Main`

### File Organization

- One class per unit file when possible
- Forms: `.pas` + `.dfm` pairs in `src/forms/`
- Business logic classes in `src/classes/`
- Match file name to unit name: unit `WRunner.Apps.Entities` → `WRunner.Apps.Entities.pas`

### Uses Clause Ordering

Organize `uses` clauses in this order, separated by blank lines:

```pascal
uses
  // 1. RTL units (System.*)
  System.SysUtils, System.Classes, System.Generics.Collections,
  // 2. Windows API (Winapi.*)
  Winapi.Windows, Winapi.Messages,
  // 3. VCL units (Vcl.*)
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  // 4. Project units (WRunner.*)
  WRunner.Apps.Entities;
```

### Formatting

- **Indentation:** 2 spaces (no tabs)
- **Line endings:** CRLF (Windows)
- **Encoding:** UTF-8 with BOM (Delphi standard)
- **Line length:** Keep under 120 characters; break long statements naturally
- **Blank lines:** One blank line between methods; no trailing blank lines

### Types & Patterns

- Use `TObjectDictionary<TKey, TValue>` for owned collections (from `System.Generics.Collections`)
- Prefer `const` parameters for strings and interfaces where possible
- Use `try..finally` for resource cleanup; `try..except` for error recovery
- Keep VCL form logic in form units; extract business logic to `src/classes/`

### Error Handling

- Use `try..finally` for deterministic cleanup (freeing objects, unlocking resources)
- Use `try..except` to catch and handle specific exceptions; avoid bare `except`
- Do not swallow exceptions silently — log or re-raise with context
- The compiler's range checking (`{$R+}`) and overflow checking (`{$Q+}`) are enabled in Debug builds

### Comments

- Use `//` for inline comments
- Use `{ }` for section/block comments only
- Do not add redundant comments that restate the code

## Architecture Notes

- **TMainForm** (`forms/Main.pas`): System tray app managing the launcher. Detects Windows dark/light theme via Registry, responds to `WM_SETTINGCHANGE` for live theme updates.
- **TWRunnerForm** (`forms/WRunnerFrm.pas`): Borderless launcher window with search input and results list.
- **TDesktopEntity** (`classes/WRunner.Apps.Entities.pas`): Data model holding app metadata (DisplayName, ParsingName, LaunchCommand).
- Application starts minimized to tray (`Application.ShowMainForm := False`).

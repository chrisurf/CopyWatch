# App

## Purpose

App lifecycle and cross-cutting application state: the process entry point,
dispatch between GUI and headless CLI modes, the single shared `AppState`
observable object, and small formatting helpers used across the UI.

## Scope & Boundaries

- Owns: `main.swift` (entry point + `--headless` dispatch), `CopyWatchApp.swift`
  (SwiftUI `App` scene), `AppDelegate.swift`, `AppState.swift` +
  `AppState+Projects.swift` (the one shared observable model the Views bind to),
  `Headless.swift` (scriptable CLI driving Engine directly, for verification
  without the GUI), `Format.swift` (byte/speed/date formatting).
- Does NOT own: copy/verify/hash logic (belongs to `Engine`), persistence
  (belongs to `Store`), device/volume detection (belongs to `System`), or any
  SwiftUI view body beyond the top-level `App`/`Scene` wiring (belongs to `Views`).
- New work of kind "global app state" or "cross-view shared state" goes in
  `AppState.swift`/`AppState+Projects.swift`; a new headless subcommand goes in
  `Headless.swift`; a new formatter goes in `Format.swift`.

## Conventions

- `AppState` is the single source of truth Views read/mutate — do not introduce
  a second competing app-wide state container.
- `Headless.main` must stay a thin CLI wrapper over `Engine`/`Store` calls; it
  exists so engine behavior can be exercised and verified without the GUI —
  don't let engine logic accrete here.

## Child DOX Index

(leaf — no child AGENTS.md)

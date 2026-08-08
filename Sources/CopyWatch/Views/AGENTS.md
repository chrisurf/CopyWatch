# Views

## Purpose

SwiftUI presentation layer — every screen, sheet, and reusable view in the app.

## Scope & Boundaries

- Owns: all `*View.swift` / `*Sheet.swift` files (`HomeView`, `ContentView`,
  `SidebarView`, `ProjectsDashboardView`, `ProjectWorkspaceView`,
  `NewProjectSheet`, `ProjectImportSheet`, `DestinationsView`,
  `DropDestinationSheet`, `NewJobSheet`, `JobDetailView`, `DeviceView`,
  `VolumeView`, `CompareView`, `BenchmarkView`, `SpeedGraph`, `AboutView`).
- Does NOT own: copy/verify/hash/scan logic, persistence, or device/volume
  detection — a View reads `AppState` and calls into `Engine`/`Store`/`System`;
  it never implements their behavior inline (Global Constraint).
- New work of kind "a new screen, sheet, or reusable presentational component"
  goes here. New engine/system behavior needed by a view still belongs in
  `Engine`/`System` — extend that seam and have the view call it.

## Conventions

- Views bind to `AppState` (from `App`) rather than owning their own parallel
  copy of app-wide state.
- Keep formatting (bytes/speed/dates) in `Format.swift` (`App`) rather than
  reimplementing it per view.

## Child DOX Index

(leaf — no child AGENTS.md)

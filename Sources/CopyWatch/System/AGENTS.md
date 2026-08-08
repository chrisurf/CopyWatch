# System

## Purpose

macOS system integration: everything that talks to the OS, Finder, or attached
storage rather than to the app's own data model.

## Scope & Boundaries

- Owns: `CardDetector.swift` (recognizing camera/drone/GoPro/audio-recorder
  cards by on-disk structure), `DeviceCatalog.swift`, `DeviceWatcher.swift`,
  `VolumeWatcher.swift` (mount/unmount + connection events), `FinderInfo.swift`
  (tags/metadata preservation), `SystemServices.swift`, `TrashFinder.swift`
  (move-to-Trash, never permanent delete), `UpdateChecker.swift`.
- Does NOT own: copy/verify/hash behavior (`Engine`), what a "project" or "job"
  is (`Models`), rendering device/volume state (`Views` reads System's output,
  System never imports SwiftUI).
- New work of kind "detect/watch/query something about the Mac, a volume, or
  an external device" goes here.

## Conventions

- Never perform a permanent delete — file removal goes through
  `TrashFinder`'s move-to-Trash path (Global Constraint).
- Device/card recognition is structural (on-disk layout), not name-based —
  don't add a detection path that keys off a volume name or label.

## Child DOX Index

(leaf — no child AGENTS.md)

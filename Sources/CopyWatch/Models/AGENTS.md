# Models

## Purpose

Plain data types shared across `Engine`, `Store`, `System`, and `Views` — the
nouns of the app (a job, a project, a file record, a volume reference).

## Scope & Boundaries

- Owns: `CopyJob.swift`, `Project.swift`, `FileRecord.swift`,
  `ComparisonRecord.swift`, `BenchmarkResult.swift`, `DestinationPreset.swift`,
  `VolumeRef.swift`.
- Does NOT own: any behavior beyond small, pure computed properties/helpers on
  the type itself (e.g. `VolumeRef.resolve()`); engine logic, persistence
  logic, and view logic all belong to their own scopes and should depend on
  these types, not the other way around.
- New work of kind "a new durable/shared data shape" goes here. If a type is
  only ever used inside one other subsystem and never crosses a boundary, it
  can live local to that subsystem instead — don't add it here just because
  "it's a model."

## Conventions

- Keep these types free of imports on `Engine`/`Store`/`System`/`Views` — the
  dependency direction is one-way, models are the shared base.
- Prefer `struct`/`enum` value types; a model gaining engine-style behavior
  (I/O, hashing, device queries) is a placement smell — that behavior belongs
  in `Engine`/`System`.

## Child DOX Index

(leaf — no child AGENTS.md)

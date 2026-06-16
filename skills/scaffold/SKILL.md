---
name: scaffold
description: Generate a complete feature scaffold across the project's layers, following its real conventions. Use when starting a new feature, endpoint, or module and you want the boilerplate laid down consistently. Mirrors the existing architecture instead of imposing one, and scaffolds only the layers the project actually uses.
---

# Scaffold

Lay down a new feature the way *this* project already does it — same layers, same patterns, same
conventions — so the new code looks like it was always there.

## 1. Learn the project's shape first

- Read an existing comparable feature end to end. That's the template, not a generic blueprint.
- Identify the real architecture (layered, vertical slices, single project…), naming, folder layout,
  error-handling and validation approach, and how requests flow from entry point to data.
- Use the project profile from `init`/CLAUDE.md if present. Don't assume Clean Architecture or any
  pattern the project doesn't use.

## 2. Generate, mirroring conventions

- Produce the files the feature needs across the layers the project actually has — entry point
  (endpoint/controller/handler), application logic, domain types, data access, DTOs, registration —
  named and placed like the existing code.
- Apply `clean-code-core` and the active pack: inject abstractions, thin entry points, validation at
  the boundary, DTOs not entities, the project's result/error pattern.
- **Scaffold only what's needed.** Don't generate layers, interfaces, or abstractions the feature
  doesn't use just to fill a template — that's over-engineering. A simple feature gets a simple
  scaffold.

## 3. Include tests and wiring

- Add tests matching the project's test conventions (see the `test` skill) for the real paths.
- Wire up DI registration, routing, and configuration so it compiles and runs — not orphan files.

## 4. Verify and hand off

Confirm it builds (`verify`). Summarize what was created and what the developer still needs to fill
in (business logic, real validations). Flag any decision worth a `plan` or ADR. Reply in the
developer's language; code and identifiers in English.

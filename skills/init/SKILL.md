---
name: init
description: Onboard Supercode to a project. Use once per project, or when the developer asks to set up, analyze, or adapt standards to this codebase. Detects the language/stack and real conventions, picks the matching pack, and writes a short project profile so every other skill adapts to this repo instead of imposing.
---

# Init

Teach Supercode about *this* project so it adapts rather than imposes. Run once (or to refresh after
a big change). The output is a short, honest profile — not a rewrite of the codebase.

## 1. Detect the stack

Identify the language(s) and stack from real markers, not guesses:

- Project files: `*.csproj`/`*.sln`, `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`,
  `Cargo.toml`, `pom.xml`/`build.gradle`, etc.
- Framework signals (web framework, ORM, test runner, build tool).
- Map to a Supercode **stack pack** if one matches (e.g. .NET). If none matches, the universal core
  applies on its own — that's fine.

## 2. Learn the real conventions

Read a representative slice of the code and infer how *this* team actually works:

- Naming, file/folder layout, architecture style (layered, vertical slices, etc.).
- Error-handling approach, testing approach, logging, DI usage.
- Note where the project **diverges** from ideal standards — these are facts to respect, not defects
  to fix now. Supercode applies standards to new/touched code without breaking what exists.

## 3. Confirm, don't assume

- Ask the developer about anything you can't reliably infer: company overlay (frozen doc templates,
  language for generated docs), deployment targets, conventions that aren't visible in the code.
- Never fabricate a convention to fill a gap.

## 4. Write the profile

Produce a concise project profile (append to the project's `CLAUDE.md`, or create one) capturing:

- Stack and the active Supercode pack.
- The project's real conventions and known divergences.
- Any company overlay to activate, and the language for generated docs.

Keep it short and true. A profile that overstates consistency is worse than none — it makes Supercode
impose a tidiness the repo doesn't have. Reply in the developer's language; keep the written profile's
code/identifiers in English.

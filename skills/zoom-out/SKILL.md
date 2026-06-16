---
name: zoom-out
description: Map an unfamiliar area of the codebase before diving in. Use when the developer doesn't know a section of code well, asks how something fits together, or needs the big picture of a module and its callers. Goes up a level of abstraction and returns a map, not a line-by-line read.
---

# Zoom out

When you (or the developer) don't know an area well, don't start editing — go up a level first and
build a map. Understanding the terrain prevents changes that break things you couldn't see.

## Produce a map

- **The area's job.** What this module/subsystem is responsible for, in one or two sentences, using
  the project's own domain vocabulary.
- **Key components.** The main types/files and what each is for — not every file, the ones that
  matter.
- **Callers (who depends on this).** What calls into this area and why. These are who you'd affect by
  changing it.
- **Dependencies (what this depends on).** What this area calls out to — DBs, services, other modules.
- **Main flows.** The one or two primary paths through it (e.g. "request → handler → service → repo →
  DB"), so the shape is clear.
- **Boundaries & contracts.** The public surface others rely on — the part you must not break casually.

## How

- Use search/grep to find definitions and references; read the entry points and follow the main
  flow, not every branch. Read excerpts, not whole files — you're mapping, not auditing.
- Speak in the project's ubiquitous language; if there's a glossary or `CLAUDE.md`, use its terms.
- Call out anything surprising: hidden coupling, a god-object, a flow that doesn't match the names.

End with where the developer should look first for the task at hand. Reply in the developer's
language; keep code identifiers in English.

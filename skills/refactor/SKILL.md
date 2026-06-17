---
name: refactor
description: Improve the structure of existing code without changing its behavior. Use when asked to refactor, clean up, reduce duplication, or pay down tech debt. Works in small, safe, verifiable steps behind a test safety net — never a big-bang rewrite.
---

# Refactor

Refactoring changes structure, not behavior. The code does the same thing afterward — just cleaner.
If behavior must change, that's a feature or a fix, not a refactor; say so and treat it as one.

Unlike `review` (which reports), this skill changes code — so it does so safely.

## 1. Establish a safety net first

- Refactoring without tests is just editing and hoping. Before changing behavior-bearing code,
  make sure there are tests that pin the current behavior.
- If coverage is missing, write **characterization tests** first: capture what the code does *now*
  (even if imperfect), so any accidental behavior change is caught.
- Confirm the net is green before touching anything (`verify`).

## 2. One transformation at a time

- Make a single, named refactoring (extract function, rename, introduce parameter object, replace
  conditional with polymorphism, inline needless indirection…), then **re-run the tests**.
- Keep each step small enough that, if a test breaks, the cause is obvious. Commit-sized steps.
- Never mix refactoring with behavior changes in the same step — they must be distinguishable in the
  diff and the history.

## 3. Aim by the hierarchy

- Target real smells (see `clean-code-core/reference/smells.md`): duplication of *knowledge*, long
  methods, primitive obsession, feature envy, switch-on-type, low cohesion.
- Move toward clean code **and** away from over-engineering. Removing a speculative abstraction or a
  middle-man layer is as valid a refactor as extracting a function. Apply `anti-overengineering` — but
  if the abstraction is a seam others depend on, flag it first (see §4) rather than deleting it freely.
- Stop when the code is clean enough for the change at hand. Don't gold-plate; don't refactor the
  whole module because you were in there.

## 4. Respect scope and the project

- Refactor what the task touches. Flag adjacent debt as `[IMPROVEMENT]`/`[TECHNICAL]`; don't silently
  expand the blast radius.
- Match the project's existing conventions, not your preferences.
- Don't break public contracts (APIs, signatures, message schemas) under the banner of "cleanup"
  without calling it out.

## 5. Finish verified

End green: tests pass, build clean (`verify`). State what you changed and confirm behavior is
unchanged. Reply in the developer's language; keep code and identifiers in English.

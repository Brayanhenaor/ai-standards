---
name: anti-overengineering
description: Guard against over-engineering before and while writing code. Use when about to build or implement something from scratch, hand-roll a custom solution, add a dependency, introduce an abstraction/layer/pattern, or when a solution feels heavier than the problem. Pushes for the simplest thing that is still clean — questioning whether the code needs to exist at all, whether the standard library or platform already does it, whether a proven library already solves it (don't reinvent the wheel), and whether it can be done in fewer moving parts.
---

# Anti-Over-Engineering

The best code is the code you never wrote. Before adding anything — a dependency, an abstraction, a
layer, a pattern, a config knob — run it through the gate below. Be lazy, not negligent: simplicity
never overrides correctness, security, accessibility, or data-loss prevention.

This skill is the counterweight to clean code, not its enemy. They share one rule:
**does this earn its place with real, present value?** Clean code adds structure that pays for
itself; this skill removes structure that doesn't.

## The decision tree (before writing code)

1. **Does it need to exist at all?** Is this solving a real, present requirement — or a hypothetical
   one? If no one needs it now, don't build it. (YAGNI)
2. **Does the standard library already do it?** Reach for built-ins before anything else.
3. **Does the platform/framework already provide it?** A native feature beats a hand-rolled one and
   beats a new dependency.
4. **Is it already a dependency you have?** Use what's installed before adding something new.
5. **Is it small? Can it be a few lines of obvious code?** For something trivial, a clear owned
   implementation beats taking on a whole library for one helper. This applies to *small* things only
   — see the next point.
6. **Is it complex and already solved by a validated library? Then don't reinvent the wheel.** For a
   hard, well-solved problem — charts/dashboards, auth, crypto, dates/timezones, parsing, schema
   validation, state management, PDF, i18n — a battle-tested official or community-standard package is
   the *clean* choice. Hand-rolling it yourself is the over-engineering: more code, more bugs, more
   maintenance than the library carries. Use it.
7. **Otherwise:** the minimal solution that is still clean — no speculative knobs, no "framework,"
   no layers the problem didn't ask for.

## Dependencies — the test cuts both ways

A dependency decision fails in **both** directions, and over-engineering lives at both extremes:

- **Adding one you don't need** — a new dependency is a permanent liability (supply-chain risk,
  updates, breaking changes, bundle size). Don't pull a library for something trivial, native, or a
  few clean lines you could own.
- **Refusing one you do need** — reinventing a complex, already-solved problem by hand is *also*
  over-engineering (Not-Invented-Here). You ship more code, more bugs, and more maintenance than a
  validated package would have carried. Building your own chart engine, auth, or date math instead of
  using the proven library is not "simpler" — it's the heavier, riskier path.

The test: **does the library do real, non-trivial work you shouldn't own — and is it well-maintained
and validated?** If yes, use it; that *is* the simple, clean choice. Prefer official or
community-standard packages, prefer one well-scoped library over several overlapping ones, and don't
pull a whole framework for a single helper. Then use it as intended — don't wrap it in needless
abstraction "just in case you swap it later."

## Abstraction & structure

- Don't add an interface, base class, generic, factory, or layer for a single concrete case that has
  no real reason to vary. Wait for the second real case; commit on the third (rule of three).
- Don't build configuration for values that have exactly one value.
- Don't generalize a function for inputs it will never receive.
- A design pattern is a tool for a present problem, never a goal. Naming a class `…Factory`,
  `…Manager`, or `…Strategy` is not an achievement.

## Simplify existing code

When code is more complicated than the problem demands:

- Collapse needless indirection (wrappers and middle-men that only forward).
- Replace a clever construction with the obvious one — readability over cleverness.
- Delete dead code and unused parameters/branches.
- Inline an abstraction that has exactly one user and no prospect of a second.

## How to report

Distinguish the two failure modes when you flag something:

```
[OVER]   Structure/dependency/abstraction with no present value — propose the simpler form
[UNDER]  Missing structure causing a god-method/duplication — that's a clean-code fix, not this
```

Always say *why* the simpler version is sufficient, and confirm it doesn't sacrifice a non-negotiable
(correctness, security, accessibility, data safety). When the simpler path loses something real, say
so — don't simplify blindly.

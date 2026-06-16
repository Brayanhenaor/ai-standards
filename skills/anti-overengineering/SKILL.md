---
name: anti-overengineering
description: Guard against over-engineering before and while writing code. Use when adding a dependency, introducing an abstraction/layer/pattern, or when a solution feels heavier than the problem. Pushes for the simplest thing that is still clean — questioning whether code needs to exist at all, whether the platform already does it, and whether it can be done in fewer moving parts.
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
5. **Can it be a few lines of obvious code?** A small, clear, owned implementation often beats taking
   on a whole library (and its updates, CVEs, and breakage) for one function.
6. **Otherwise:** the minimal solution that is still clean — no speculative knobs, no "framework,"
   no layers the problem didn't ask for.

## Dependencies

- A new dependency is a permanent liability: supply-chain risk, updates, breaking changes, bundle
  size. Add one only when it does real, non-trivial work you shouldn't own yourself.
- Prefer one well-scoped library over several overlapping ones. Don't pull a large framework for a
  single helper.

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

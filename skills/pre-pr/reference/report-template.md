# Pre-PR — report template

The report is written to `pre-pr-review.md` (repo root, overwritten each run) **and** printed. It is
the evidence attached to the PR, so it must be self-contained and traceable. Write the body in the
**developer's language** (it's a generated deliverable — same rule as `adr`/`changelog`). Keep in
English only what is always English: code, identifiers, `file:line`, snippets, and the fixed
verdict/severity tokens (`Critical`, `High`, `✅ Ready`, …) that keep the mapping deterministic.

Fill every section. Omit a section only when it is genuinely empty, and say so ("None.") rather than
dropping it silently. Render findings with the tiered format from `severity.md`.

```markdown
# Pre-PR Review

**Source → Target:** <source-branch> → <target-branch>
**Scope:** <branch diff (base...source) | working tree (staged/unstaged) | both>
**Commit range:** <merge-base-sha>..<source-head-sha>  (<N> commits)
**Change type:** <feature | bugfix | refactor>   **Ticket:** <id or —>
**Date:** <YYYY-MM-DD>

## Executive summary
<2–4 lines: what the change is, and the verdict at a glance.>

## Findings by severity
<Grouped, highest first, using the tiered format. Cap Low/Suggestion at 5 + a collapsed line.>

## Count
Critical <n> · High <n> · Medium <n> · Low <n> · Suggestion <n>

## Tests
- [x]/[ ] The change includes tests for the new behavior
- [x]/[ ] Tests are behavior-focused (survive a harmless refactor)
- [x]/[ ] Suite builds and passes

## What's done well
<Real strengths of the change. Not filler — if there's nothing notable, say so.>

## Risks
<Risks that remain even if the PR is opened as-is.>

## Assumptions & things to verify
<Context-dependent observations the reviewer could not confirm from what it read — phrased as
questions, not findings. E.g. "Validation of `userId` is assumed to happen in the controller, outside
this diff — confirm." If everything was confirmable, say "None.">

## Priority recommendations
<Ordered list of what to fix before opening the PR.>

## Overall quality
<An honest assessment. Not an inflated grade.>

## ADR
<✅ Covered by ADR-XXXX | ⚠️ ADR-XXXX should be updated | ⚠️ ADR recommended |
 ❗ ADR required before the PR | ✅ No ADR needed> — <one-line justification, citing the ADR if any>

## Verdict
<✅ Ready for the PR | ⚠️ Ready for the PR, with risks | ❌ Not ready for the PR>
<1–2 lines: the reason, tied to the blockers.>
```

After writing the file, print the same content and finish with:

```
Evidence written to ./pre-pr-review.md
```

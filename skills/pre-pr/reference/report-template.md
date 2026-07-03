# Pre-PR — report template

The report is written to `pre-pr-review.md` (repo root, overwritten each run) **and** printed. It is
the evidence attached to the PR, so it must be self-contained and traceable.

## Language — read carefully (this is where reports go wrong)

- Write the **entire report in the developer's language** — every section heading, every field label,
  all prose, the severity names, and the verdict. The skeleton below is in English **only because
  plugin content is English**; **translate the headings and labels** when you render (a Spanish report
  has Spanish headings: `## Resumen ejecutivo`, `**Qué:**`, `Veredicto`, `Crítico`…).
- Keep in English **only** what is genuinely English and would look forced translated:
  - code, identifiers, file paths and `file:line`, and code snippets — always;
  - established dev-domain terms teams say in English (endpoint, middleware, deadlock, race condition,
    N+1, async/await, thread-safety, nullable…) — used naturally inside the sentence.
- Do **not** leave headings, labels, or ordinary words in English out of habit. The deterministic
  verdict is internal logic — it is not a reason to print English labels.

## Findings — structured blocks, never paragraphs

Render each finding with the fixed block from `severity.md` (heading + bold labels + fenced code),
grouped by severity, highest first. Never write a finding as running prose. Cap Low/Suggestion at 5
plus a collapsed line. Labels shown here in English are rendered in the developer's language.

    ### [<Severity>] <category> · path:line
    **What:** <one plain sentence>

    ```<lang>
    <the actual offending lines from the diff>
    ```

    **Why it matters:** <the concrete consequence>
    **Fix:** <the concrete change; before → after when it helps>
    **Confidence:** <high | needs confirmation: what to check>   ·   **Effort:** <quick-fix | needs-design> *(optional)*

## Structure

Fill every section. Omit one only when genuinely empty, and say so ("None.") rather than drop it.
Headings below are the canonical set — **render them in the developer's language.**

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
<The structured finding blocks, grouped highest-first. Cap Low/Suggestion at 5 + a collapsed line.>

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
<Context-dependent observations the reviewer could not confirm — phrased as questions, not findings.
E.g. "`userId` validation is assumed to happen in the controller, outside this diff — confirm." If
everything was confirmable, say "None.">

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

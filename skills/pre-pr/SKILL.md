---
name: pre-pr
description: Final pre-PR review — the check a Staff Engineer runs before opening a pull request. Use when the developer is about to open/create a PR, asks to "review my PR", "check before the PR", "is this ready for a pull request", or wants PR review evidence. Gathers context (which branches, or working tree), reviews only the PR diff across all Supercode engines (clean-code, security, performance, concurrency, migration, tests), emits a severity-ranked report with a 3-state verdict and an ADR recommendation, and writes it to pre-pr-review.md as evidence to attach to the PR.
---

# Pre-PR Review

One command the developer runs before opening a pull request. It reviews **only the code in the
PR**, thinks like a Staff Engineer doing the final review, and produces a professional report —
shown in the terminal and written to `pre-pr-review.md` as evidence to attach to the PR.

**Compose, don't reimplement.** Every rule already lives in another skill/agent. This skill
orchestrates them over the PR diff, adds the checks they don't cover (tests, PR size, docs drift,
new dependencies), consolidates, and reports. It never copies rule text — one source of truth.

Read `reference/rules.md` (what to check + how to avoid false positives), `reference/severity.md`
(the impact-based rubric and the deterministic verdict mapping) and `reference/report-template.md`
(the frozen report) before running.

## Invocation

```
/supercode:pre-pr            # interactive: confirms scope, asks only what it can't infer
/supercode:pre-pr --ci       # non-interactive: states its assumptions, compact output (pipelines)
```

## 1. Context — ask, never assume

**A) PR scope — always confirmed with the developer.** Never start reviewing on an assumed scope.

- **What is reviewed?** A PR between two branches, the uncommitted **working tree**, or both.
- **Source** (current branch) and **target** (base) branch. Infer a proposal
  (`source` = current branch; `target` = `origin/HEAD` → `main`/`master`) but **put it in the
  question for the developer to confirm or correct**.
- If working tree is chosen, confirm staged / unstaged / both.

**B) Change context — infer first, ask only what's ambiguous.** Auto-derive from branch name,
commit messages, an embedded ticket, the PR template, `CLAUDE.md`, and existing ADRs. Then ask,
dynamically, only what's still material and unknown: the goal / problem solved, the change type
(feature / bugfix / refactor), the ticket, technical or business constraints, prior architectural
decisions to respect. **Prefer a question over a hallucination** — if something matters and can't be
derived, ask before continuing. In `--ci` mode, skip the questions and state the assumptions used.

## 2. Resolve the diff — real PR scope

The PR diff is the **merge-base** diff, not "working tree vs HEAD":

```
git diff --merge-base <target> <source>     # equivalently: git diff <target>...<source>  (three-dot)
```

Include uncommitted work if the developer chose to. Detect the stack(s) from project markers.
**Review only this diff** — no findings on untouched code, no legacy refactors, unless the change
directly worsens or depends on an existing defect. If the diff is empty, say so; don't invent
findings. For a large diff, review by module in parallel and **state coverage** — never imply
coverage you didn't do.

## 3. Fan-out — run the existing engines over the diff

Dispatch in parallel, each restricted to the diff's file set:

- **`code-reviewer`** agent — clean code, SOLID, naming, smells, over-engineering, potential bugs,
  breaking changes, English-only new code, comments, magic strings, idiomatic language/framework use.
- **`security-auditor`** agent — OWASP, secrets, authz, injection, unsafe deserialization.
- **`performance`** — algorithms, N+1, allocations, collection misuse, async misuse, memory/resource leaks.
- **`concurrency`** — races, deadlocks, shared mutable state, thread-safety.
- **`migrate`** — only if the diff touches schema/migrations: safety, data-loss, breaking changes.

## 4. Tests — first-class check

- The new behavior / bugfix **has tests** covering it.
- Tests are **behavior-focused**, not implementation-locked.
- The suite **runs and passes** (`verify`).

A bugfix with no regression test, or new public behavior with no test, is **High** (see
`reference/severity.md`). Use the `test` skill's judgment for quality; don't reinvent it.

## 5. Build & tests

Run `verify` — build plus the test suite. A red build or failing tests is a Critical blocker.

## 6. Consolidate + adversarial self-review

Merge findings, drop duplicates. Then, before reporting, re-check each one:

- It is **in the diff**.
- It is **justified against a rule** — not a style preference.
- For Critical/High: its **reachability/impact is proven**, not assumed.

Drop anything that fails. Cap low-severity noise (see the rubric). A confident wrong finding costs
more than a missed nitpick.

## 7. Verdict, ADR, evidence, report

- Map severities → verdict with the **deterministic rule** in `reference/severity.md`
  (✅ ready · ⚠️ ready with risks · ❌ not ready).
- Evaluate the **ADR** recommendation (✅ / ⚠️ / ❗) using the `adr` skill's criteria.
- Render the report from `reference/report-template.md`, **write it to `pre-pr-review.md`** at the
  repo root (overwrite each run; don't commit or gitignore it — it's PR evidence), and print the same
  report. End with: `Evidence written to ./pre-pr-review.md`.

This skill **reviews and reports — it does not fix code**. Hand fixes back to the relevant skill.
Write the report (on screen and in `pre-pr-review.md`) in the developer's language, since it's a
generated deliverable attached to the PR. Keep in English only what is always English: code,
identifiers, `file:line`, snippets, and the fixed verdict/severity tokens (`Critical`, `High`,
`✅ Ready`, …) so the deterministic mapping stays stable.

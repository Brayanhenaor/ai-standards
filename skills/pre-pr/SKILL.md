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

## 0. Context tool — detect, confirm, index, freshness

Run this once, before step 1.

1. **Detect capability, prefer `codebase-memory-mcp`, degrade gracefully.** Look at what's connected
   this session for the roles below: indexing a repo, checking index status/drift, searching or
   tracing symbols/call chains, fetching a precise code range by symbol, running a graph query,
   summarizing architecture, managing ADRs in a graph. Preference order:
   1. `codebase-memory-mcp` — the org default. Use it for every role it covers.
   2. Any other connected knowledge-graph/context MCP covering the same roles (e.g. Graphify or
      similar) — use it for whichever role `codebase-memory-mcp` doesn't cover, or in full when
      `codebase-memory-mcp` isn't connected. Discover its actual tool names from what's connected —
      don't assume they match `codebase-memory-mcp`'s (mapping in `reference/rules.md` § Context tool).
   3. Nothing connected at all — go to step 2 below.
   Match every tool by *role*, never by hardcoding a function name — the mapping is re-derived from
   what's connected each run, for either tool.

2. **Nothing connected?** Don't install it yourself. Note it as one item for the single question round
   in step 1 (don't ask in isolation) — recommend `codebase-memory-mcp` as the default (or another
   graph MCP they already use), and explain it would cut this review's tokens/time meaningfully
   (bounded graph lookups replace full-file reads across every engine). If they decline or don't
   answer, continue with direct file reads for the rest of this run; never block on this.

3. **Connected, project not indexed?** Index it now — local, non-destructive, safe without asking.
   Use the lightest mode that still yields call-graph and architecture data.

4. **Connected and indexed, but stale for this branch?** Check whether the graph reflects the current
   diff via whatever drift/change-detection that MCP exposes. If the tool has no explicit drift check,
   fall back to a heuristic: compare its last-indexed commit/timestamp (from its status output) against
   the current `HEAD` and treat any difference as stale. If stale, refresh it (incremental/fast mode)
   before relying on it — a stale graph gives silent false negatives, worse than no graph.

5. **Fresh and available:** use it as the default source for callers/definitions/architecture/
   reachability/ADR lookups through steps 1C, 2, 3, 4, and 6 below. Fall back to a direct read only for
   what it doesn't cover (e.g. a brand-new file added in this diff has no node yet).

6. **Incremental rerun shortcut.** If `pre-pr-review.md` already exists for this branch and its
   **Context tool** metadata line names a tool, skip straight to the freshness check (point 4) with
   that tool — don't re-run capability detection (points 1-3) from scratch on every rerun.

## 1. Context — ask, never assume

**One question round, not sequential prompts.** Collect every open question this run needs — the
step-0 MCP decision (if nothing was connected), PR scope (A), and change context (B) — and ask them
together in a single message. Don't drip them one at a time; each round-trip reloads context for
nothing.

**A) PR scope — always confirmed with the developer.** Never start reviewing on an assumed scope.

- **What is reviewed?** A PR between two branches, the uncommitted **working tree**, or both.
- **Source** (current branch) and **target** (base) branch. Infer a proposal
  (`source` = current branch; `target` = `origin/HEAD` → `main`/`master`) but **put it in the
  question for the developer to confirm or correct**.
- If working tree is chosen, confirm staged / unstaged / both.

**B) Change context — infer first, ask only what's ambiguous.** Auto-derive from branch name,
commit messages, an embedded ticket, the PR template, and `CLAUDE.md`. Then ask, dynamically, only
what's still material and unknown: the goal / problem solved, the change type (feature / bugfix /
refactor), the ticket, technical or business constraints, prior architectural decisions to respect.
**Prefer a question over a hallucination** — if something matters and can't be derived, ask before
continuing. Questions are a primary tool and stay open through the whole review, not just here (see
step 6). In `--ci` mode, skip the questions and state the assumptions used.

**C) Read the relevant ADRs as context — gated, not unconditional.** Only do this when the diff looks
architectural (see the trigger list in `reference/rules.md`) — new external integration, schema or
persistence change, public-contract change, new core dependency, security-model change. When
triggered: use the graph's ADR-lookup capability first (step 0) for nodes matching the topic, and read
only the ones that match — not every file under `docs/adr/`. They carry intent,
constraints, and the architectural baseline the change must respect. Use them two ways: to
**suppress false positives** (what looks wrong may be a deliberate, documented decision) and to
**catch real problems** (a change that contradicts or silently supersedes a recorded decision is an
architecture finding). This feeds the whole report, not only the ADR verdict in step 7. When the
diff isn't architectural, skip this substep entirely — the ADR verdict in step 7 defaults to
**✅ No ADR needed**.

## 2. Resolve the diff — real PR scope

The PR diff is the **merge-base** diff, not "working tree vs HEAD":

```
git diff --merge-base <target> <source>     # equivalently: git diff <target>...<source>  (three-dot)
```

Include uncommitted work if the developer chose to. Detect the stack(s) from project markers.
**Report only on this diff** — no findings on untouched code, no legacy refactors, unless the change
directly worsens or depends on an existing defect.

**Judge with bounded context, not unbounded reads.** For each changed symbol, pull its **direct**
callers/definitions and touched config — via the graph's call-chain/snippet capability (step 0) when
available, or a targeted read when it isn't. Direct means one hop; don't chase the transitive closure.
Reading is not scoped to the diff; findings are.

**Incremental re-runs.** If `pre-pr-review.md` already exists for this branch, read its commit range.
If the source branch has only added commits since (no rebase/force-push), only re-review the new
commits' diff and any file a prior finding pointed at — carry forward untouched findings instead of
re-deriving them.

If the diff is empty, say so; don't invent findings. For a large diff, review by module in parallel,
**capped at 4 concurrent modules** — batch the rest and say so in the report; never imply coverage you
didn't do.

## 3. Fan-out — run only the engines this diff needs

**Shared context pass first, once.** Before dispatching any engine, gather what they'd all otherwise
fetch independently: the graph's architecture summary (once, step 0), the bounded caller/definition
context from step 2, and touched config. Hand this as evidence to every engine below instead of
letting each re-read the same files. This is the single biggest cost cut — don't skip it.

**Small diff (< 5 files and < 150 changed lines): one combined pass.** Run a single `code-reviewer`
call covering the full checklist (clean code, security, performance, concurrency) instead of spinning
up four separate agents — each agent call pays fixed overhead regardless of diff size, and a small
diff doesn't need four specialists to each say "clean".

**Larger diff, or the shared pass flags a specialist concern: dispatch gated by trigger, in parallel**
— see the trigger table in `reference/rules.md`. Always run `code-reviewer` above this size; the rest
only when triggered:

- **`code-reviewer`** agent — clean code, SOLID, naming, smells, over-engineering, potential bugs,
  breaking changes, English-only new code, comments, magic strings, idiomatic language/framework use.
- **`security-auditor`** agent — triggered by auth/authz/secrets/token/policy files, input validation,
  CORS, external API calls, or any new endpoint.
- **`performance`** — triggered by hot-path/loop code over real data, new or changed queries, new
  collections, or async changes.
- **`concurrency`** — triggered by shared mutable state, threading, background workers/consumers, or
  async coordination — skip entirely on stacks with no concurrency surface (e.g. a static frontend diff).
- **`migrate`** — only if the diff touches schema/migrations: safety, data-loss, breaking changes.

**Breaking-change reachability** (see Correctness & safety in `reference/rules.md`): when a public
API/contract/DTO changed, confirm real consumers with the graph's cross-cutting query capability
(step 0) before calling it Critical — don't assume reachability from reading the changed file alone.

## 4. Tests — first-class check

- The new behavior / bugfix **has tests** covering it — check via the graph's query capability first
  (does the changed symbol have an incoming edge from a test node?) before scanning test directories
  by hand.
- Tests are **behavior-focused**, not implementation-locked.
- The suite **runs and passes** (`verify`).

A bugfix with no regression test, or new public behavior with no test, is **High** (see
`reference/severity.md`). Use the `test` skill's judgment for quality; don't reinvent it.

## 5. Build & tests

Run `verify` — build plus the test suite. A red build or failing tests is a Critical blocker.

## 6. Consolidate + adversarial self-review

Merge findings, drop duplicates, then run the **confidence & context gate** in
`reference/severity.md`: every finding must be in the diff, justified against a rule, and **grounded
in context actually read** — not inferred from a line in isolation. If a judgment depends on code or
config the reviewer hasn't seen, it **reads it first**; if it still can't confirm, it does **not**
emit a hard finding — in interactive mode it **asks the developer** to resolve the ambiguity (batch
the questions); only if it still can't confirm does it move the observation to the report's
*Assumptions & things to verify* section as a question. Use the developer's answers — from step 1 and
from these follow-ups — to suppress findings the context already explains. Cap low-severity noise. A
wrong blocker costs more than a missed nitpick.

This consolidation is **one orchestrator pass**, not a second fan-out of verifier agents — the
confidence gate is a checklist the orchestrator applies itself. Reserve the graph-backed reachability
check (step 3) for Critical/High breaking-change claims specifically; don't spawn extra agents to
re-verify Medium/Low findings.

Render findings in the **legible format** (`reference/severity.md`): the actual code, a plain-language
explanation, and a concrete fix — never a cryptic one-liner for a real issue.

## 7. Verdict, ADR, evidence, report

- Map severities → verdict with the **deterministic rule** in `reference/severity.md`
  (✅ ready · ⚠️ ready with risks · ❌ not ready).
- Evaluate the **ADR** recommendation. If the change is architectural, **search for an existing ADR
  first, then ask the developer if one exists and where** before concluding — never assume none
  exists (see `reference/severity.md`). Emit ✅ covered / ⚠️ update / ⚠️ recommended / ❗ required /
  ✅ not needed, citing the ADR when one is involved.
- Render the full report from `reference/report-template.md` and **write it to `pre-pr-review.md`**
  at the repo root (overwrite each run; don't commit or gitignore it — it's PR evidence). In the
  terminal, print only the **condensed echo** (see `reference/report-template.md`) — not the full
  findings blocks a second time. End with: `Evidence written to ./pre-pr-review.md`.

This skill **reviews and reports — it does not fix code**. Hand fixes back to the relevant skill.
Write the **entire report** (on screen and in `pre-pr-review.md`) in the developer's language — every
section heading, field label, severity name, and the verdict included. It's a deliverable attached to
the PR. Keep in English **only** what is genuinely English and would look forced translated: code,
identifiers, file paths and `file:line`, code snippets, and established dev-domain terms teams say in
English (endpoint, middleware, deadlock, race condition, N+1, async/await…), used naturally in the
sentence. Don't leave headings, labels, or ordinary words in English out of habit — the deterministic
verdict is internal logic, not a reason to print English labels. See `reference/report-template.md`
for the language rule and the finding block structure.

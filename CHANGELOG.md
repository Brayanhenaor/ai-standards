# Changelog — supercode

All notable changes are documented here. Format: [Semantic Versioning](https://semver.org/).

---

## [0.1.13] — 2026-11-26

### Added
- `pre-pr`: **Structural measurement** pass that runs before every engine — method length and growth,
  mixed responsibilities, parameter counts (methods and endpoints), constructor dependencies, public
  types per new file, and input validation inside endpoints. Every hit is reported or explicitly
  justified, so structural debt no longer slips through hunk by hunk.
- `pre-pr`: request validation belongs in the request model (DataAnnotations / `IValidatableObject` /
  FluentValidation per project).

### Changed
- `pre-pr`: clean-code rule measures before judging instead of deferring to "no absolute line count";
  organization rule is one public top-level type per new file; Medium calibration examples cover
  oversized service methods, long query parameter lists, and DTOs inside service files.

---

## [0.1.12] — 2026-11-19

### Added
- `pre-pr`: **High-impact patterns** section in `reference/rules.md` — defects that look harmless line
  by line but cost money, data, or a breach: unauthenticated endpoints that mutate/expose data and
  fail-open global filters; client-controlled state flags trusted before the persisted value;
  idempotency keys not scoped per tenant (including derived keys); side effects emitted outside the
  transaction; check-then-act without a constraint and uniqueness-assuming conversions; culture-
  sensitive parsing of money/dates; insecure config defaults; seeders that overwrite live state or run
  in every environment; background batches blocked by one bad item; partial updates that clear data.
- `pre-pr`: **Connections & pool** check under Correctness & safety (connections closed, no context
  captured by singletons/background services, no per-item context in loops).
- `pre-pr`: **Claimed fixes** check — when a change says it fixes tracked defects, verify each one
  (fixed / partial / open) and look for regressions introduced by the fix.
- `pre-pr`: **Merge artifacts** check (duplicated project-file entries, conflict leftovers).
- `pre-pr`: severity **calibration examples** in `reference/severity.md`.
- `security-auditor`: fail-open auth filters, hardcoded bypass values, anonymous mutating endpoints,
  tenant-unscoped keys, missing TLS, insecure config defaults, demo credentials or test bypasses in
  production code.

### Changed
- `pre-pr`: the language rule for new code now follows the **project's policy** (`CLAUDE.md` / `init`
  profile) instead of always flagging non-English comments; identifiers stay English by default; log
  messages and user-facing text are never flagged for language.
- `pre-pr`: tests for transactions, concurrency, constraints, or migrations that run on an in-memory
  provider or a mocked mediator no longer count as coverage for those behaviors.
- `pre-pr`: `security-auditor` is also triggered by added/removed auth attributes and changes to
  global request filters/middleware.

## [0.1.10] — 2026-07-09

### Changed
- `pre-pr`: dispatch is now **gated**, not a fixed fan-out. `security-auditor`/`performance`/
  `concurrency` only run when the diff triggers them (auth files, hot paths, shared state — see the
  trigger table in `reference/rules.md`); a small diff (< 5 files, < 150 lines) gets one combined
  `code-reviewer` pass instead of four separate agent calls.
- `pre-pr`: engines no longer each independently re-read the same files. A single shared context pass
  (architecture, direct callers/definitions, config) runs once and is handed to every dispatched
  engine.
- `pre-pr`: ADR search is now gated to diffs that look architectural, instead of running on every diff.
- `pre-pr`: "read freely" is now **bounded to direct callers/definitions** (one hop), not the
  transitive closure of everything a changed line touches.
- `pre-pr`: large diffs cap module-parallel review at 4 concurrent modules and state what's batched,
  instead of unbounded fan-out.
- `pre-pr`: incremental re-runs reuse the previous `pre-pr-review.md` commit range and only re-review
  new commits, instead of re-deriving every finding from scratch each run.
- `pre-pr`: terminal output is now a **condensed echo** (summary, count, verdict, priority
  recommendations, full Critical blocks) instead of reprinting the entire file content a second time.
- `pre-pr`: adopted a knowledge-graph MCP as the primary context tool for bounded caller context,
  architecture summaries, breaking-change reachability, test-coverage checks, and ADR lookup — new
  step 0 detects it **by capability, not by a hardcoded tool name**, so the mapping (today
  `codebase-memory-mcp`) can change without rewriting the skill. Falls back to raw reads when nothing
  is connected or a capability isn't covered.
- `pre-pr`: not locked to a single vendor — prefers `codebase-memory-mcp` (org default) but falls back
  to any other connected graph/context MCP (e.g. Graphify or similar) for a role `codebase-memory-mcp`
  doesn't cover or when it isn't connected at all. Staleness check also has a generic heuristic
  fallback (compare last-indexed commit vs `HEAD`) for tools with no explicit drift-detection call.
- `pre-pr`: breaking-change reachability now opportunistically checks cross-repo/service consumers
  (e.g. `cross-repo-intelligence` mode) against **already-indexed** projects only — never triggers a
  fresh index of an unrelated repo just for this check.
- `pre-pr`: all developer-facing questions (MCP install decision, PR scope, change context) are now
  batched into **one question round** instead of sequential prompts, each of which reloads context.
- `pre-pr`: the report now records which context tool was used (`Context tool` metadata line). An
  incremental rerun reads this first and skips straight to the freshness check instead of re-running
  capability detection from scratch every time.
- `pre-pr`: step 0 now handles the full lifecycle before relying on the graph — detect whether an MCP
  is connected (**ask the developer for confirmation** before suggesting installation; never installs
  it or blocks on the answer), index the project if it isn't yet (no confirmation needed, local and
  non-destructive), and refresh the graph if it's stale for the current branch, before any engine
  trusts it for context.
- `pre-pr`: clarified that the confidence-gate consolidation is one orchestrator pass, not a second
  fan-out of verifier agents — reachability re-verification is reserved for Critical/High only.

## [0.1.11] — 2026-07-15

### Changed
- `clean-code-core`: added an explicit "Comments — default to none" rule (zero unnecessary
  comments; never narrate *what* the code does or address the developer in-code; only a
  non-obvious *why*). Previously this was only implied via a code-smell table row, easy to miss.

### Added
- New `PreToolUse` hook (`hooks/skill-reminder.sh`) on `Write|Edit` for code files: injects a
  non-blocking reminder to apply `clean-code-core` + `anti-overengineering` before the edit lands,
  instead of relying solely on the model choosing to invoke those skills on its own judgment.

## [0.1.9] — 2026-07-03

### Fixed
- `pre-pr`: report language no longer mixes English into a non-English report. The **whole** report —
  section headings, field labels, severity names, verdict — is rendered in the developer's language;
  English is kept only for what is genuinely English (code, identifiers, `file:line`, snippets, and
  dev-domain terms teams say in English). Removed the earlier "keep verdict/severity tokens in
  English" rule that was the source of the gratuitous mixing — the deterministic verdict is internal
  logic, not a reason to print English labels.
- `pre-pr`: findings now render as a **structured block** (heading + bold labels + fenced code block),
  never a paragraph with code inlined. `What` / `Why it matters` / `Fix` / `Confidence` each on its
  own line, the offending code always in its own fence — so the evidence scans cleanly.

## [0.1.8] — 2026-07-03

### Changed
- `pre-pr`: the ADR check no longer assumes none exists. For an architectural change it **searches
  for an existing ADR** (repo location + common paths, matched by topic) and, if none is found,
  **asks the developer whether one exists and where** before concluding. New outcomes: ✅ covered by
  an existing ADR (cited), ⚠️ an existing ADR should be updated (change diverges/supersedes it), in
  addition to ⚠️ recommended / ❗ required / ✅ not needed. Prevents a false "ADR required" when one
  already exists.
- `pre-pr`: relevant ADRs are now **read as context that feeds the whole report**, not just checked
  for existence. They provide intent, constraints, and the architectural baseline — used both to
  suppress false positives (a documented, deliberate decision) and to catch real problems (a change
  that contradicts or silently supersedes a recorded decision is an architecture finding, cited).

## [0.1.7] — 2026-07-03

### Changed
- `pre-pr`: findings are now **legible evidence** — each shows the actual offending code, a
  plain-language explanation of the concrete consequence (not just a rule name), and a concrete fix
  (before → after when it helps). Cryptic one-liners are no longer acceptable for real issues.
- `pre-pr`: fewer false positives from missing context. The reviewer **reads freely to judge but
  reports only on the diff** (reading the whole changed file, referenced definitions/callers, and
  config is in scope; only findings are diff-scoped). It leans hard on **questions to the developer
  throughout the review** — not just at the start — whenever a finding hinges on context only the dev
  holds, asking before deciding instead of guessing. When it still can't confirm (or in `--ci` mode),
  the observation moves to a new **Assumptions & things to verify** report section as a question,
  never a hard blocker.

## [0.1.6] — 2026-07-03

### Fixed
- `pre-pr`: the report is written in the developer's language (same rule as `adr`/`changelog`), since
  it's a generated deliverable attached to the PR — not forced to English. Only code, identifiers,
  `file:line`, snippets, and the fixed verdict/severity tokens stay in English so the deterministic
  mapping is unaffected.

## [0.1.5] — 2026-07-03

### Added
- **`pre-pr`** skill — the final review a Staff Engineer runs before opening a pull request. One entry
  point that: confirms scope with the developer (which branches, or the working tree) and gathers
  change context without assuming; reviews **only the PR diff** (merge-base `base...source`) by
  composing the existing engines (`code-reviewer`, `security-auditor`, `performance`, `concurrency`,
  `migrate`, `verify`) — no rule is reimplemented; adds the checks they don't cover (tests as a
  first-class check, PR size/cohesion, new dependencies, documentation drift); reports findings on an
  impact-based 5-level severity rubric with a **deterministic** verdict mapping (✅ / ⚠️ / ❌) and an
  ADR recommendation; and writes the report to `pre-pr-review.md` as evidence to attach to the PR.
  Anti-false-positive tuning baked in (no idiomatic-lambda naming nits, magic values scoped to
  business literals, capped low-severity noise).

## [0.1.4] — 2026-06-16

### Changed
- Balance audit across all skills. `scaffold`: confirm the file list/shape with the developer before
  generating, and apply `anti-overengineering` (don't hand-roll auth/validation/parsing a validated
  library solves). `test`: propose the standard fakes/assertion library (license + consent) instead
  of hand-rolling test doubles. `refactor`: flag a seam others depend on before removing it.
  `changelog`: state uncertainty instead of fabricating when the diff doesn't support it.

## [0.1.3] — 2026-06-16

### Added
- Package license & consent gates in `anti-overengineering` (and surfaced in `clean-code-core`):
  only propose libraries that are free for commercial use (MIT/Apache-2.0/BSD/ISC/MPL); flag
  non-free/copyleft licenses with alternatives; and never add a dependency silently — the developer
  always confirms (use it / use another / build it).

## [0.1.2] — 2026-06-16

### Changed
- "Don't reinvent the wheel" is now **default behavior**, not only an opt-in skill: added the
  reach-for-proven-solutions principle to `clean-code-core` (always-on), and widened the
  `anti-overengineering` trigger to fire when about to build something from scratch / hand-roll a
  custom solution. Targets the common reflex of implementing from zero when a validated library
  already solves the problem.

## [0.1.1] — 2026-06-16

### Fixed
- `anti-overengineering`: the dependency decision now cuts both ways. Reinventing a complex,
  already-solved problem by hand (Not-Invented-Here) is flagged as over-engineering too — a
  validated official/community library for charts, auth, crypto, dates, parsing, etc. is the clean
  choice. Added a "don't reinvent the wheel" branch to the decision tree.

## [0.1.0] — 2026-06-16

Restructured from the `ai-standards` npx installer into an installable **Claude Code plugin**
(`/plugin`), rebuilt as a universal clean-code toolset.

### Added
- Plugin manifest + single-repo marketplace (`.claude-plugin/`).
- **Universal core:** `clean-code-core` (with SOLID/naming/functions/abstraction/smells reference),
  `anti-overengineering`, `verify`.
- **Reasoning & change skills:** `plan`, `debug`, `commit`, `refactor`, `init`, `grill`, `zoom-out`,
  `standup`, `gate`, `migrate`.
- **Review:** `review` skill + `code-reviewer` agent; `security-audit` skill + `security-auditor`
  agent.
- **Analysis lenses:** `architect`, `concurrency`, `performance`, `domain`.
- **Generation:** `scaffold`, `test`.
- **.NET pack** (`dotnet`): conventions, DI, errors, EF Core, API, resilience, observability,
  caching, messaging, security, testing, Docker — rebuilt at current .NET 8–10 standards.
- **Company-profile doc skills:** `adr`, `changelog`, `tech-doc` (official templates preserved).
- **Hook:** `secret-scan` (blocks commits containing likely secrets).

### Changed
- Rules audit applied: `IExceptionHandler` + ProblemDetails RFC 9457, OpenTelemetry/`Meter` as the
  vendor-neutral observability path, `TimeProvider`, source-generated logging, keyed services,
  `EnableRetryOnFailure`, free assertion libraries, chiseled Docker images.
- Language model is now adaptive (replies in the developer's language; all artifacts in English).

---

## ai-standards (pre-restructure)

## [2.0.0] — 2026-05-19

### Added — New commands

**Expert lenses:**
- `security-dotnet` — standalone security audit (JWT, OWASP Top 10, injection, secrets, PII, CORS, CVEs)
- `migrate-dotnet` — EF Core migration safety analysis (zero-downtime, lock types, NOT NULL pattern, expand-contract)
- `messaging-dotnet` — MassTransit/RabbitMQ/Service Bus expert (idempotency, outbox, sagas, schema evolution)
- `cache-dotnet` — caching expert (IMemoryCache, Redis, HybridCache, stampede protection, invalidation)
- `api-dotnet` — REST API contract design (HTTP semantics, versioning, pagination, ProblemDetails, OpenAPI)
- `refactor-dotnet` — guided tech debt refactoring (smell detection, characterization tests, atomic steps)

**Workflow meta-commands:**
- `gate-dotnet` — pre-PR orchestrator (build, tests, review, security, migrations, messaging, commit, docs)
- `start-dotnet` — feature kickoff (requirements, 2-option design, branch, scaffold outline, post-scaffold checklist)

**New rules:**
- `error-handling.md` — Result<T> vs exceptions, ProblemDetails RFC 7807, exception hierarchy, logging levels
- `messaging.md` — message naming, idempotency, outbox, schema evolution, retry, correlation IDs
- `caching.md` — when to cache, key naming, TTL guidelines, stampede protection, PII rules
- `api-design.md` — REST conventions, status codes, versioning, pagination, ProblemDetails

**New hooks:**
- `secret-scan.sh` — PreToolUse/Bash: blocks git commit with embedded secrets (JWT, AWS keys, connection strings)
- `format-check.sh` — Stop: reports dotnet format violations after turns with .cs changes

### Changed

- `tech-manual.md` → renamed to `manual-dotnet.md` for naming consistency (all commands now follow `{verb}-dotnet` pattern)
- `global/settings.json` — fixed bug: `cs-dirty-flag.sh` was not registered, causing `build-check.sh` to never fire; added `Edit` event for dirty flag; added new hooks
- `README.md` — updated with all 25 commands organized by lifecycle phase (Discover, Plan, Design, Build, Validate, Ship, Operate, Maintain)
- `bin/cli.js` — corrected command count (18), improved hooks description

### Lifecycle coverage (v2.0)

```
DISCOVER  → init-dotnet, manual-dotnet
PLAN      → plan-dotnet, adr-dotnet
DESIGN    → architect-dotnet, domain-dotnet, api-dotnet
BUILD     → scaffold-dotnet, migrate-dotnet, cache-dotnet, messaging-dotnet
VALIDATE  → review-dotnet, security-dotnet, test-dotnet, concurrency-dotnet, performance-dotnet
SHIP      → commit-dotnet, changelog-dotnet
OPERATE   → debug-dotnet, grafana-dotnet, docker-dotnet, infisical-dotnet
MAINTAIN  → refactor-dotnet, standup
WORKFLOW  → gate-dotnet, start-dotnet
```

---

## [1.1.0] — 2024-xx-xx

### Added
- Cursor IDE support with interactive wizard
- `init-dotnet` — project initialization with full analysis and CLAUDE.md generation
- `architect-dotnet`, `concurrency-dotnet`, `performance-dotnet`, `domain-dotnet` — expert lenses
- `scaffold-dotnet` — complete feature scaffold across all layers
- `grafana-dotnet` — Prometheus dashboard generation
- `infisical-dotnet` — secrets provider configuration
- `adr-dotnet` — Architecture Decision Record generation
- `changelog-dotnet` — change control document generation
- `docker-dotnet` — Docker/Compose review and generation
- `debug-dotnet` — structured debugging protocol

### Rules added
- `csharp-conventions.md`, `di-lifetimes.md`, `docker.md`, `resilience.md`
- `security.md`, `testing.md`, `ef-advanced.md`, `observability.md`

---

## [1.0.0] — 2024-xx-xx

### Added
- Initial release: `plan-dotnet`, `review-dotnet`, `commit-dotnet`, `test-dotnet`, `standup`, `tech-manual`
- Global `CLAUDE.md` with universal work rules, language conventions, debugging protocol
- NPX installer with Claude Code support
- 4 hooks: `build-check.sh`, `test-runner.sh`, `migration-guard.sh`, `cs-dirty-flag.sh`

---

## How to update in a project

```bash
# Check current version
cat ~/.claude/commands/gate-dotnet.md | head -3

# Update globally
npx github:Brayanhenaor/ai-standards

# Select what to update (standards / commands / rules / hooks)
```

Breaking changes (command renames) are noted explicitly. Non-breaking additions require no action in existing projects.

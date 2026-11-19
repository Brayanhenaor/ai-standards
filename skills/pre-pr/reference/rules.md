# Pre-PR — rules catalog

What a Staff Engineer checks before approving a PR, and — just as important — the nuances that keep
false positives out. Each area names the engine that already owns the rule; `pre-pr` applies it over
the PR diff, it does not redefine it.

**Golden rule for every finding:** it must be *in the diff*, justified against a rule, and worth a
senior reviewer's breath. Report real problems, not the pursuit of perfect code. When in doubt
between flagging a nitpick and staying silent, stay silent.

---

## Context tool

`pre-pr` gets most of its callers/definitions/architecture/reachability/ADR context from a connected
knowledge-graph MCP instead of raw file reads — see the detect → confirm → index → freshness flow in
SKILL.md §0. That flow is written against **capabilities**, not a fixed tool contract: match whatever
is connected by role, don't require an exact function name.

**Preference order:** `codebase-memory-mcp` (org default) first; any other connected graph/context MCP
(e.g. Graphify or similar) as a fallback, or to fill a role `codebase-memory-mcp` doesn't cover; direct
reads only when nothing connected covers a role.

**Capability → what it replaces** (`codebase-memory-mcp` names shown as the preferred mapping — for
any other connected tool, discover its actual tool names from its own schema instead of assuming they
match; re-derive both mappings against what's actually connected each run, don't hardcode either):

| Capability needed | Replaces | `codebase-memory-mcp` (preferred) |
|---|---|---|
| Index status / trigger index / detect drift | Confirming the graph is usable before trusting it | `index_status`, `index_repository`, `detect_changes` |
| Direct callers/definitions of a changed symbol | Opening the whole file to trace usage by hand | `trace_path`, `search_graph` |
| Exact code range for a symbol | Reading a full file to find one function | `get_code_snippet` |
| Project architecture/structure summary | Each engine exploring folders independently | `get_architecture` |
| Cross-cutting graph query (reachability, test coverage, custom traversal) | Manual grep across the repo, or guessing | `query_graph` |
| ADR lookup by topic | Grepping and reading every file under a docs/adr folder | `manage_adr`, `query_graph` |

A different connected tool satisfies the same row through whatever it calls its own equivalent — match
by the "Capability needed" column, not by the exact names in the last one. If the connected tool(s)
don't cover a role at all, fall back to a direct read for that piece only — don't block the whole
review on a partially-covering graph.

## Dispatch — what triggers what

Not every engine runs on every diff. `code-reviewer` always runs above the small-diff threshold
(< 5 files and < 150 changed lines → one combined pass instead, see SKILL.md §3). The rest are gated:

| Engine | Trigger |
|---|---|
| `security-auditor` | Files matching auth/authz/secrets/token/policy/permission patterns, input validation, CORS, external API calls, any new endpoint, any added/removed auth attribute (e.g. `[AllowAnonymous]`, `[Authorize]`), or a change to a global request filter/middleware |
| `performance` | Hot-path/loop code over real data, new or changed queries, new collections, async changes |
| `concurrency` | Shared mutable state, threading, background workers/consumers, async coordination — skip entirely on stacks with no concurrency surface |
| `migrate` | Any file under `**/Migrations/**` or equivalent schema-change path |

When unsure whether a trigger applies, run the engine — a missed trigger costs more than an extra
agent call on an ambiguous diff. The gate is for the clearly-inapplicable case, not a coin flip.

---

## Correctness & safety (always outranks everything)

- **Potential bugs** — null/none dereferences, unhandled edge cases, missing validation, logic
  errors, unhandled or swallowed exceptions, silent failures, inconsistent state.
- **Security** (`security-auditor`) — vulnerabilities, hardcoded secrets, exposed sensitive data,
  injection, missing auth/authz, unsafe deserialization. Confirm the path is reachable with
  attacker-controlled input before calling it Critical.
- **Concurrency** (`concurrency`) — races, deadlocks, thread-safety, shared mutable state,
  unnecessary locking, misused async/await, unsafe parallelism.
- **Memory & resources** (`performance`) — memory/resource leaks, undisposed objects, unbounded
  growth, badly-implemented caches, possible OOM.
- **Connections & pool** — every manually opened connection/command/reader is closed in
  `finally`/`using`; no DB context or connection captured by a singleton or a long-lived background
  service; no new context/connection per item inside a loop. A leak here saturates the pool and takes
  the whole service down under load — always check it when the diff touches data access.

## Performance (`performance`)

Inefficient algorithms, repeated expensive operations, **N+1 queries**, inefficient loops,
needless allocations, excessive object creation, inefficient collection use, wrong async usage,
obvious optimization opportunities. **Nuance:** flag on evidence (hot path, loop over real data,
per-request cost), not on speculative micro-optimization. Don't trade readability for a nanosecond.

## Breaking changes

Changes that break compatibility: public APIs, contracts, method signatures, serialization shapes,
DB schema (→ `migrate`), config keys, event/message schemas, DTOs, behavior changes on an existing
path. **Nuance:** distinguish **published/consumed** surface (real breaking change) from purely
internal symbols (not one). Say who breaks and how.

**Cross-repo check (opportunistic).** If the connected graph tool exposes cross-repo/service
reachability (e.g. `codebase-memory-mcp`'s `cross-repo-intelligence` mode) over **already-indexed**
projects, use it to confirm real external consumers of a changed public contract — stronger evidence
than reading the changed file alone. Only query against repos already indexed; never trigger a fresh
index of an unrelated repo just for this check — that cost isn't worth one reachability check.

## Clean code (`clean-code-core`)

Over-long methods, over-large classes/files, high complexity, duplication, high coupling, low
cohesion, poor readability, hard-to-maintain code. **Nuance:** judge against the project's real
conventions, not an absolute line count. Flag the pattern with impact, not a metric for its own sake.

## SOLID (`clean-code-core`)

Apply where it earns its place — especially SRP, Dependency Inversion, Open/Closed. **Nuance:** a
SOLID "violation" is only a finding when it causes a real maintainability cost here; don't demand
interfaces for a single concrete case that has no reason to vary (that's over-engineering — below).

## Separation of responsibilities

Each class / method / function / service / component has one clear responsibility. Flag the
god-method and the class that does three unrelated things.

## Naming (`clean-code-core/reference/naming.md`)

Clear, self-explanatory, consistent, English names for variables, functions, parameters, classes,
interfaces, constants. **Nuance — critical for false positives:** only flag names whose **scope or
lifetime is non-trivial** (a field, a public method, a variable that lives many lines). **Do NOT**
flag single-letter parameters in short, idiomatic lambdas/loops (`x`, `i` in `.Select(x => x.Id)`
or a two-line loop) — that is idiomatic and a senior reviewer waves it through.

## Language of new code — follow the project's policy

Default: identifiers, methods, and comments in **new** code are in English; flag non-English or
mixed-language ones. **The project's own policy wins** — read it from `CLAUDE.md`, the `init`
profile, or `CONTRIBUTING` before flagging. A team may keep English identifiers but allow comments in
its own language; then flag only identifiers. **Nuance:** never flag legacy/untouched code; keep domain
terms with no English equivalent (proper nouns, legal/business terms) as-is; never flag log messages
or user-facing text (UI, API error messages, localization) for language.

## Comments

Only comments that add value survive: business rules, architectural decisions, complex algorithms,
technical limitations, external constraints. Flag comments that restate what the code already says.
**Nuance:** don't flag doc comments required by the project's convention (e.g. public-API XML/JSDoc).

## Magic values

Flag literals that **encode a business decision or identifier** and whose meaning isn't obvious, or
that **repeat** — e.g. `clientId = "91322"` → named constant. **Nuance — critical for false
positives:** do NOT flag trivial literals (`0`, `1`, `-1`, `""`, `true`), obvious HTTP status codes
in place, or test data. Exclude user-facing messages, UI text, and localization resources.

## Over-engineering (`anti-overengineering`)

Needless abstractions, patterns for their own sake, excessive configuration, forwarding wrappers,
premature generalization, extra layers, unnecessary complexity. Favor the simplest solution that is
still clean. Flag the *over*-structured as readily as the *under*-structured.

## Idiomatic language / framework use (`anti-overengineering`)

Use the language/framework's own capabilities: native APIs, standard library, official best
practices, idiomatic code. If a native solution exists, don't pull a dependency. If there's no
native solution and a widely-adopted, maintained library exists, don't reinvent the wheel. **New
dependency** → apply the license & consent gate (commercial-free license; developer confirms).

## Organization

Prefer one class per file and a clear, consistent structure **when it fits the project's
architecture**. **Nuance:** not an absolute — respect language norms (nested/private helper types,
Go's file model) and the repo's existing convention.

## Architecture

The change respects the project's existing architecture **and the decisions recorded in its ADRs**.
ADR search is gated to diffs that look architectural — not run unconditionally (see SKILL.md §1C).
When triggered, read the ADRs that touch what the change modifies: a change that contradicts or
silently supersedes a recorded decision is a finding — cite the ADR. Flag a new pattern that fights
the established one. Use `architect`/`domain` judgment for cross-boundary design.

---

## High-impact patterns — check these explicitly

Defects that look harmless line by line but cost money, data, or a breach in production. Each one has
slipped through real reviews; apply them whenever the diff touches the area. Same confidence gate as
everything else: confirm the path is reachable before calling it Critical.

- **Unauthenticated surface that mutates or exposes data.** A new endpoint opted out of auth
  (`[AllowAnonymous]`, a route excluded from a middleware, a public handler) that creates/updates
  records, triggers side effects, or returns business data for a tenant id taken from the request.
  Also read the global filter/middleware it relies on: a filter that **fails open** (lets the request
  through when the token is unknown, or only fails when a header is missing) or a **hardcoded bypass
  value** in code makes every opted-out endpoint effectively public.
- **Client-controlled state used before persisted state is loaded.** A status/flag that comes in the
  request payload (`posted`, `processed`, `paid`, `emitted`, `contabilized`…) used to skip a
  validation or choose a branch, when the authoritative value is only read from the DB later — or
  never. The caller sets the flag and bypasses the rule. Decide on the persisted value.
- **Idempotency scope.** Idempotency keys must be unique per tenant/owner (e.g. per establishment or
  company), not globally — and keys **derived** from a request key (`prefix:{key}`) inherit that scope.
  When an "already exists" lookup short-circuits a side effect (a debit, a stock movement, an
  emission), verify the existing record belongs to **the same entity** before skipping; otherwise one
  tenant's key silently cancels another tenant's operation.
- **Side effects outside the transaction.** Notifications, push, e-mail, realtime events, webhooks, or
  external calls emitted before commit, or emitted regardless of whether the operation failed and
  rolled back. Users get told about things that never happened. Emit after commit (outbox / post-commit
  hook) and drop the queue on failure.
- **Check-then-act without a constraint.** "Look it up, insert if missing" (or "count, then use
  count+1") without a unique index or atomic statement creates duplicates under concurrency. Watch the
  consumer too: converting such data with a uniqueness-assuming call (`ToDictionary`, `Single`, a map
  keyed by id) turns one duplicate row into a permanent exception on every later request.
- **Culture-sensitive parsing of money, quantities, and dates.** Parsing numbers/dates that come from
  text produced elsewhere (another system, a comment field, a file) with the server's culture —
  e.g. `decimal.Parse("1234.56")` on a server whose culture uses `,` as decimal separator silently
  yields `123456`. Parse/format with an invariant culture and explicit date kind/offset.
- **Insecure defaults in code.** Config fallbacks that pick the unsafe option when a key is missing:
  a development secret as the default value, `GetValue("UseInMemory", true)`, auth checks that turn
  off when an option is unset. Missing config must fail fast at startup (e.g. options validation on
  start), never degrade silently into an insecure or non-persistent mode.
- **Startup seeders and init jobs.** Demo/sample data seeded in every environment, seeders that
  **overwrite** live state on each boot (re-enable a record an operator disabled, reassign ownership),
  or migrations/seeding that run concurrently from every replica. Seed demo data only in development,
  insert-only, and keep schema migration as a deploy step or behind a lock.
- **Background jobs and batches.** One bad item aborting the whole batch with a single save — and the
  next run picking the same items first — blocks the job forever. Process and persist per item/group,
  quarantine failures, and claim work across replicas (`FOR UPDATE SKIP LOCKED`, advisory lock). Also
  flag queues/outbox tables that receive messages nobody consumes or purges (unbounded growth, and
  retained personal data).
- **Partial updates that clear data.** An update endpoint that maps absent fields to empty/false
  (proto3 scalars without `Has*`, non-optional booleans, JSON fields defaulting to `null`) wipes
  values the caller never meant to change. Map "not sent" to "keep current".

---

## Checks `pre-pr` adds (not covered by the other engines)

- **Tests** — see SKILL.md §4. Missing regression test for a bugfix, or new public behavior with no
  test → **High**. A test that claims to cover transactions, concurrency, unique constraints, or
  migrations but runs on an in-memory provider or a mocked mediator/repository **does not count** as
  coverage for that behavior — those providers don't enforce any of it.
- **Claimed fixes** — when the change says it fixes tracked defects (bug ids, audit findings), list
  each one and verify it point by point in the diff: fixed / partial / still open. Then check the fix
  didn't regress adjacent behavior: a handler emptied or removed, an early `return` that now skips
  logic that used to run, an authorization marker added without the matching route/registration.
- **Merge artifacts** — duplicated entries in project/manifest files (e.g. the same
  `<Compile Include>` twice), leftover conflict markers, files re-added by a bad merge.
- **PR size & cohesion** — a PR that does several unrelated things should be split. High-value, very
  low false-positive. Flag mixed concerns ("this PR changes auth *and* reformats an unrelated
  module — split it").
- **New dependencies** — a package added in the diff: is it needed, is its license commercially free,
  is it maintained? (Reuse the `anti-overengineering` gate.)
- **Documentation drift** — a contract/endpoint/env var/config changed but README / API docs /
  CHANGELOG weren't updated.
- **Error handling & observability** — swallowed exceptions, logging PII/secrets, wrong log level,
  missing correlation on cross-service calls.
- **Config / flags / deployment** — a new env var or feature flag with no safe default or no
  documentation; deployment-affecting change not surfaced.
- **Idempotency & retries** — network/messaging code that isn't safe to retry.

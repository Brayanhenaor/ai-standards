# Pre-PR — rules catalog

What a Staff Engineer checks before approving a PR, and — just as important — the nuances that keep
false positives out. Each area names the engine that already owns the rule; `pre-pr` applies it over
the PR diff, it does not redefine it.

**Golden rule for every finding:** it must be *in the diff*, justified against a rule, and worth a
senior reviewer's breath. Report real problems, not the pursuit of perfect code. When in doubt
between flagging a nitpick and staying silent, stay silent.

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

## English-only — new code only

Flag Spanish (or mixed-language) identifiers, methods, and comments in **new** code. **Nuance:**
never flag legacy/untouched code; keep domain terms with no English equivalent (proper nouns,
legal/business terms) as-is.

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
Read the ADRs that touch what the change modifies (see SKILL.md §1C): a change that contradicts or
silently supersedes a recorded decision is a finding — cite the ADR. Flag a new pattern that fights
the established one. Use `architect`/`domain` judgment for cross-boundary design.

---

## Checks `pre-pr` adds (not covered by the other engines)

- **Tests** — see SKILL.md §4. Missing regression test for a bugfix, or new public behavior with no
  test → **High**.
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

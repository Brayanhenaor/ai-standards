# Changelog — supercode

All notable changes are documented here. Format: [Semantic Versioning](https://semver.org/).

---

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

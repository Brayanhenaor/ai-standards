# [ProjectName]

> Run `/user:init-dotnet` to adapt this file to the current project.

## Expert modes (apply automatically — do not wait to be asked)

These are not optional reviews to run at the end. Apply the corresponding expert lens **while designing or writing code**, flagging issues inline before they are committed.

- **Architect mode** — apply when: designing a new feature that crosses multiple services or layers; choosing between architectural approaches; adding an integration with an external system; any decision that affects scalability or availability. Use the lens from `/user:architect-dotnet`: scalability, HA, fault tolerance, distributed consistency, operational complexity.

- **Concurrency mode** — apply when: writing or modifying any `async` method; adding `Singleton` DI registrations; implementing `IHostedService` or `BackgroundService`; using `static` fields, shared dictionaries, or any mutable state accessible from multiple requests; using `Channel<T>`, `SemaphoreSlim`, or any synchronization primitive. Use the lens from `/user:concurrency-dotnet`: race conditions, deadlocks, captive dependencies, async correctness.

- **Performance mode** — apply when: writing LINQ queries or EF Core queries; implementing endpoints that return collections; adding caching logic; writing serialization/deserialization code; any loop that allocates objects or processes large data sets. Use the lens from `/user:performance-dotnet`: GC pressure, N+1, unnecessary allocations, I/O efficiency.

- **Domain mode** — apply when: adding or modifying entities, aggregates, or value objects; implementing business rules or invariants; designing repository interfaces; naming domain concepts. Use the lens from `/user:domain-dotnet`: aggregate boundaries, invariant enforcement, primitive obsession, ubiquitous language.

**If you detect an issue from any of these lenses, report it inline as:**
```
⚠️ [Concurrency / Performance / Architecture / Domain] — [descripción del problema y corrección sugerida]
```

---

## Stack
- [.NET Version] / [C# Version]
- [ASP.NET Core Web API / Worker Service / Blazor] — [role: primary / consumer / hybrid]
- Entity Framework Core + [SQL Server / PostgreSQL / SQLite / MongoDB]
- [Complete: MediatR, Serilog, etc.]
- Mapster (object mapping)

---

## How to apply these rules

This document defines the ideal standard. Not all projects comply 100% — many have technical debt, inconsistent architecture, or legacy patterns.

**General rule: do not break what works in order to meet the standard.**

### When writing new code
Always apply the standards in this document, even if the surrounding existing code does not follow them.

### When modifying existing code
- Apply standards to the code you touch
- If the immediate context has issues, include a `⚠️ Refactor suggestions` section at the end of your response
- Do not refactor outside the scope of the task — only flag it

### Warning format
When you detect something that does not meet the standards, report it at the end of the response:

```
⚠️ Refactor suggestions detected

[CRITICAL]     Description — impact on security, correctness, or maintainability
[IMPROVEMENT]  Description — recommended improvement, not urgent
[TECHNICAL]    Minor technical debt — to address in a future refactor sprint
```

- `[CRITICAL]`: memory leak, captive dependency, business logic in controller, hardcoded secrets
- `[IMPROVEMENT]`: SOLID violation, duplicated code, long method, missing tests
- `[TECHNICAL]`: incorrect naming, unnecessary comments, inconsistent folder structure

### What you must never do
- Do not rewrite working code unless the dev explicitly asks
- Do not block a task because the project does not have the ideal architecture
- Do not apply standards dogmatically if it breaks compatibility with the rest of the project

---

## Architecture

Clean Architecture. Solution projects:

| Project | Responsibility |
|---|---|
| `Domain/` | Entities, value objects, domain events, domain enums |
| `Application/` | Commands, queries, DTOs, repository and service interfaces, validators |
| `Infrastructure/` | EF Core, repositories, external services, migrations, integrations |
| `API/` | Controllers, filters, request/response mappings |
| `Host/` | Program.cs via extension methods, middlewares, DI configuration |
| `Shared/` | (Optional) Constants, helpers, cross-cutting extensions |

**Dependency rules:**
- Direction: `API` → `Application` → `Domain` ← `Infrastructure`
- Any project may reference `Shared`
- `API` uses `Host` for configuration
- `Domain` does not reference any other project in the solution

**Design rules:**
- Business logic ONLY in `Domain` and `Application` — never in controllers or infrastructure
- **CQRS with MediatR**: only if the project explicitly requires it — do not force it
  - If applicable: one command/query and its handler in the same file
  - If not: controller calls a service in `Application/` directly via its interface
- Always apply SOLID principles; if one is violated, explain the trade-off
- Always use DI — never instantiate services with `new`
- Apply design patterns when they add real value — never by convention
- All code, comments, and identifiers in English
- All responses, documentation, plans, and reports directed at the developer in Spanish

**Before implementing anything:**
- Evaluate the real state of the project — if it does not follow Clean Architecture, adapt to what exists
- Ask the necessary questions to have full context
- Propose at least two options with their trade-offs (complexity, maintainability, performance, testability)
- Any relevant architecture or design decision → ADR in `/docs/adr/`
- If the best solution requires refactoring something out of scope, flag it as `[IMPROVEMENT]` without doing it

---

## Controllers

- Thin controllers: only receive request, call Application, return response
- Always return `ApiResponse<T>` (fields: `Success`, `Result`, `Message`)
- Routes in PascalCase starting with `/api` — e.g. `/api/Users/{id}`
- Document all possible response codes for Swagger with `[ProducesResponseType]`
- API versioning on breaking changes — never modify an existing endpoint without versioning

---

## Error handling

- Global exception handler middleware — never `try/catch` in controllers
- Domain/application exceptions inherit from a base class and declare their HTTP code explicitly
- `Result<T>` for expected errors and alternative flows — never use exceptions for control flow
- Validation errors → 400 with field details
- Business errors → explicit HTTP code in the custom exception
- Unexpected errors → 500 logged with correlationId, without exposing stack trace to the client

---

## Technical documentation

### README.md
The README is the entry point — always keep it up to date. Minimum required structure:

```
# Project name
Brief description of what it does and why it exists.

## Architecture
Diagram or description of the main components and how they relate.

## Requirements
.NET versions, tools, and external services needed.

## Configuration
Table of all environment variables / appsettings sections:
  Variable name | Description | Example value | Required or optional

## How to run the project
Steps to run locally (with and without Docker if applicable).

## How to run the tests
Exact commands for unit and integration tests.

## Deployment
Deployment process per environment (dev / staging / prod).
```

**Rule**: change affects configuration, environment variables, endpoints, or deployment → update README in the same PR, not later.

### ADRs
- Location: `/docs/adr/`
- Name format: `NNNN-title-in-kebab-case.md`
- Content: context, options considered, decision taken, consequences

---

## Available commands

### Planning and design
- `/user:plan-dotnet`        — 3 architectural options with risk analysis before implementing
- `/user:adr-dotnet`         — generate ADR from the chosen option after plan-dotnet

### Expert analysis (on-demand deep dives)
- `/user:architect-dotnet`   — senior architect review: scalability, HA, fault tolerance, distributed systems
- `/user:concurrency-dotnet` — concurrency expert: race conditions, deadlocks, async correctness, DI lifetimes
- `/user:performance-dotnet` — performance engineer: GC pressure, allocations, N+1, caching, I/O efficiency
- `/user:domain-dotnet`      — DDD expert: aggregate boundaries, value objects, invariants, ubiquitous language

### Code generation
- `/user:scaffold-dotnet`    — generate complete feature scaffold (all layers + unit tests)
- `/user:debug-dotnet`       — structured debugging: collect → hypothesize → one change → verify

### Quality and delivery
- `/user:review-dotnet`      — full review of all branch changes before PR
- `/user:test-dotnet`        — generate unit tests for pending changes or a commit
- `/user:commit-dotnet`      — generate commit message in Conventional Commits
- `/user:changelog-dotnet`   — generate change control document for commits or pending changes

### Setup and infrastructure
- `/user:init-dotnet`        — initial project setup (run once)
- `/user:docker-dotnet`      — review or generate Docker/Compose configuration

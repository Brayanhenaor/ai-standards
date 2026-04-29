# [ProjectName]

> Run `/user:init-dotnet` to adapt this file to the current project.

## Context rules

**Before writing code, evaluate whether any of these rules apply and read it first.**

- **Docker** — you are writing or modifying a `Dockerfile`, `docker-compose.yml`, healthchecks, or container configuration → read `~/.claude/rules/docker.md`
- **Resilience** — you are registering an `HttpClient`, consuming an external API, integrating a third-party service, or configuring retry/timeout/circuit breaker → read `~/.claude/rules/resilience.md`
- **EF advanced** — you are writing bulk operations (`ExecuteUpdateAsync`/`ExecuteDeleteAsync`), queries with multiple joins/includes, creating migrations, or designing indexes → read `~/.claude/rules/ef-advanced.md`
- **Testing** — you are writing unit tests or integration tests → read `~/.claude/rules/testing.md`
- **Security** — you are implementing authentication, authorization, JWT, sensitive data handling, CORS, or rate limiting → read `~/.claude/rules/security.md`

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
- Apply design patterns when they add real value (Factory, Builder, Specification, etc.) — never by convention
- Clearly separated responsibilities; if a method does more than one thing, split it
- All code in English
- No obvious comments; use `/// <summary>` only when behavior is not inferrable from the name

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

## C# conventions

- `PascalCase`: classes, methods, properties, events, constants
- Constants in static classes grouped by domain (`ErrorCodes`, `PolicyNames`, `RouteConstants`, etc.) — never scattered string literals in code
- Only exception allowed: log messages (can be inline string literals)
- `camelCase`: parameters, local variables, private fields
- `I` prefix: interfaces (`IUserRepository`)
- `Async` suffix: every async method (`GetUserAsync`)
- Records for immutable DTOs and value objects
- Prefer explicit type over `var`; use `var` only when the type is obvious from the right-hand side
- Always `async/await` for I/O — never `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`
- Use `CancellationToken` in all async methods that do I/O or call external services
- Prefer `IReadOnlyList<T>` / `IEnumerable<T>` over `List<T>` in public signatures
- `switch` expressions over chained `if/else if` for multiple cases
- Use `is null` / `is not null` instead of `== null` / `!= null`
- Enable `<Nullable>enable</Nullable>` in all projects
- Do not suppress nullable warnings with `!` without a comment explaining why it is safe
- Never return `null` from a service to indicate "not found" — use `Result<T>` or throw an exception
- For collections: always return empty collection, never `null`

---

## Object mapping (Mapster)

- Use Mapster for all cross-layer mapping — never manual mapping except for very simple cases
- Mapping configs in `XMappingConfig` classes implementing `IRegister`, located in `Application/`
- Register all `IRegister` automatically at startup: `TypeAdapterConfig.GlobalSettings.Scan(assembly)`
- Inject `IMapper` via DI — do not use static `TypeAdapter.Adapt<T>()` in services
- Allowed mappings: `Entity → XResponse`, `XRequest → Entity`, `XRequest → Command/Query`
- Never map `Entity → Entity` directly for updates — assign properties explicitly so intent is clear
- If a mapping requires logic (computed fields, resolvers), document it in the `IRegister` with a technical comment

---

## DTOs and validation

- DTOs named `XRequest` (input) and `XResponse` (output) — no generic "Dto" suffix
- Validation with DataAnnotations directly on `XRequest` classes
- Enable automatic model validation with the ASP.NET Core validation filter — do not validate manually in controllers or services
- Do not duplicate validations: if EF has a constraint, do not replicate it in DataAnnotations unless the DB error is unacceptable as a client response

---

## Entity Framework Core

- Entity configuration with `IEntityTypeConfiguration<T>` in `Infrastructure/` — never data annotations in Domain
- Read queries: always `.AsNoTracking()` unless the entity will be modified
- Project with `.Select()` on read queries — never load full entity to read 2 fields
- Avoid N+1: use `.Include()` only when necessary and with judgment; prefer explicit joins for complex queries
- Pagination mandatory on endpoints returning collections — never expose unlimited endpoints
- Never expose `DbContext` outside `Infrastructure/`
- Descriptive migration names: `AddOrderAuditFields`, not `Migration20240101`
- Never modify migrations already applied in production — always create a new one

---

## Logging

- Use `ILogger<T>` in all services — never `Console.WriteLine`
- Structured logging with Serilog; always include relevant properties as context
- Levels:
  - `Debug`: internal flow, intermediate values (development only)
  - `Information`: relevant business events (request received, process completed)
  - `Warning`: unexpected but recoverable situation
  - `Error`: failure that impacts the user; always include exception if applicable
- Never log: passwords, tokens, cards, PII, connection strings
- Include `correlationId` in all logs for traceability
- Enrich with: environment, version, userId (when applicable)

---

## Configuration (Options pattern)

- Read configuration in services exclusively with `IOptions<T>`, `IOptionsSnapshot<T>`, or `IOptionsMonitor<T>` — never inject `IConfiguration` outside `Host/`
- One options class per configuration section (`SmtpOptions`, `JwtOptions`, etc.) with `.ValidateDataAnnotations().ValidateOnStart()`

---

## Dependency lifetimes

Register each service with the correct lifetime — bugs from incorrect lifetimes are silent and hard to detect:

| Lifetime | When to use |
|---|---|
| `Singleton` | No mutable state, thread-safe, expensive to create (`IHttpClientFactory`, caches, configuration) |
| `Scoped` | One instance per HTTP request (`DbContext`, repositories, business services) |
| `Transient` | Lightweight, stateless, cheap to create |

**Critical rules:**
- Never inject a `Scoped` service into a `Singleton` — captive dependency, causes concurrency bugs
- Never inject `DbContext` directly into a `Singleton` — use `IServiceScopeFactory` to create an explicit scope
- `IDisposable` registered as `Transient` inside a `Singleton` are never released — avoid this
- If a `Singleton` needs a `Scoped` service, inject `IServiceScopeFactory` and create the scope manually

---

## Security

- Connection strings exclusively from `IConfiguration` (User Secrets in dev, env vars / secrets manager in prod)
- Never hardcode credentials, tokens, or internal service URLs
- Authorization with policies (`[Authorize(Policy = "...")]`) — never role logic in controllers
- Validate and sanitize all input at the system boundary (controllers/endpoints)
- Do not expose internal database IDs in public APIs — use GUIDs or obfuscated IDs
- HTTPS mandatory; do not accept HTTP in production

---

## Performance and resource management

- Never `new HttpClient()` — always `IHttpClientFactory` to avoid socket exhaustion
- `IDisposable` / `IAsyncDisposable` on classes managing unmanaged resources; always with `using` / `await using`
- `async void` only in event handlers — in any other case use `async Task`
- Do not capture `this` in long-lived closures without unsubscribing — classic memory leak
- `StringBuilder` in loops — never `string +=` inside iterations
- `IAsyncEnumerable<T>` for streaming large volumes — never `.ToList()` on thousands of records
- Bulk operations with `ExecuteUpdateAsync` / `ExecuteDeleteAsync` — never load entities just to modify them in bulk

---

## Resilience

Every call to an external service (HTTP, queues, third parties) needs timeout + retry with backoff + circuit breaker, configured via `IHttpClientFactory` with `AddResilienceHandler` — never inline per call. Do not retry 4xx.

---

## Testing

- Libraries: xUnit + FluentAssertions + NSubstitute
- Projects: `[Name].Tests.Unit` and `[Name].Tests.Integration`
- Naming: `MethodName_Scenario_ExpectedResult`
- AAA pattern mandatory with explicit `// Arrange`, `// Act`, `// Assert` sections
- Test observable behavior, not internal implementation
- Each test independent: no shared state, no order dependency
- Integration tests: `WebApplicationFactory` for endpoints, Testcontainers or SQLite in-memory for repositories

Use `/user:test-dotnet` to generate tests for pending changes or a specific commit.

---

## Code quality and patterns

### Guard clauses

- Return or throw early for invalid cases — never nest the main logic inside `if`
- The happy path must be the main flow, without excessive indentation

```csharp
// BAD
if (user != null) {
    if (user.IsActive) {
        // main logic...
    }
}

// GOOD
if (user is null) throw new NotFoundException();
if (!user.IsActive) throw new BusinessException("User is inactive");
// main logic...
```

### Rich domain model

- Entities have behavior — they are not just property bags
- Logic that belongs to an entity goes as a method on that entity, not in a service
- Use Value Objects for domain concepts with value identity (`Email`, `Money`, `Address`)
- Avoid primitive obsession: a loose `string email` is worse than an `Email` value object with its own validation
- Domain events for decoupled side effects — do not call services directly from the entity

### Composition over inheritance

- Prefer interfaces + composition over deep inheritance hierarchies
- Maximum 2 inheritance levels; if you need more, rethink the design
- Decorators for cross-cutting behavior (logging, caching, retry) — do not inherit to add behavior

### Code smell detection

When reviewing or writing code, identify and propose solutions for:
- **Long method** (> 20 lines): extract private methods with descriptive names
- **Long parameter list** (> 3): group into a parameter object or use Builder
- **Large class** (> 300 lines): evaluate whether it has more than one responsibility (SRP)
- **Feature envy**: method using more data from another class than its own → move the method
- **Magic numbers**: any numeric literal that is not 0 or 1 → named constant

---

## What NOT to do

- No hardcoded string literals in code — use constants; exception: log messages
- No `dynamic`, no `object` as return type or parameter
- No `.Result` / `.Wait()` / `.GetAwaiter().GetResult()` in async code
- No generic `catch (Exception)` without re-throw or structured logging
- No business logic in controllers, middlewares, or infrastructure
- Never expose `DbContext` outside `Infrastructure/`
- Never return EF entities directly from the API — always DTOs/records
- No static services with mutable state
- Never add NuGet packages without discussion and evaluation of maintenance and license
- Never omit `CancellationToken` in async methods doing I/O
- Never add a new `case` to an existing `switch` without evaluating whether a pattern should be extracted

---

## Technical documentation

### README.md
The README is the entry point to the project — it must always be up to date. Minimum required structure:

```
# Project name
Brief description of what it does and why it exists.

## Architecture
Diagram or description of the main components and how they relate.

## Requirements
.NET versions, tools, and external services needed.

## Configuration
Table of all environment variables / appsettings sections with:
- Variable name
- Description
- Example value
- Whether required or optional

## How to run the project
Steps to run locally (with and without Docker if applicable).

## How to run the tests
Exact commands for unit and integration tests.

## Deployment
Deployment process per environment (dev / staging / prod).
```

**Rule**: if you make a change that affects configuration, environment variables, endpoints, or deployment process → update the README in the same PR, not later.

### ADRs
- Location: `/docs/adr/`
- Name format: `NNNN-title-in-kebab-case.md`
- Content: context, options considered, decision taken, consequences

### Code
- `/// <summary>` on non-obvious public methods, interfaces, and value objects

---

## Available commands
- `/user:init-dotnet`   — initial project setup (run once)
- `/user:plan-dotnet`   — plan a requirement with trade-offs before implementing
- `/user:review-dotnet` — full review of all branch changes
- `/user:commit-dotnet` — generate commit message in Conventional Commits
- `/user:test-dotnet`   — generate unit tests for pending changes or a commit
- `/user:docker-dotnet`    — review or generate Docker/Compose configuration
- `/user:changelog-dotnet` — generate change control document for commits or pending changes

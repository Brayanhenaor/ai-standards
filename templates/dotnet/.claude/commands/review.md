# Full code review

Perform a comprehensive review of all changes in the current branch against main.

## Step 1 — Load context

Run these commands before reviewing:
- `git diff main...HEAD` — full diff
- `git diff main...HEAD --stat` — list of changed files
- `git log main...HEAD --oneline` — commit history

## Step 2 — Review dimensions

Evaluate every changed file across all dimensions below. Not every dimension applies to every file — use judgment.

---

### Business logic
- Does the change correctly implement the intended behavior?
- Is business logic placed in Domain or Application — not in controllers, infrastructure or middlewares?
- Are edge cases handled (empty collections, nulls, boundary values)?
- Does the change affect existing behavior unintentionally?

### Architecture and SOLID
- Do dependencies respect the direction: API → Application → Domain ← Infrastructure?
- Does each class have a single responsibility?
- Are new types/behaviors added via extension rather than modifying existing classes (OCP)?
- Are abstractions used correctly — no leaking infrastructure concerns into Application or Domain?
- Are interfaces used for dependencies — no `new` for services?

### Design patterns
- Are there `if/else` or `switch` blocks that should be replaced with Strategy, Factory or polymorphism?
- Are complex business rules expressed as Specification instead of nested conditionals?
- Are there long parameter lists that should be parameter objects?
- Is there duplicated logic that should be extracted?

### Performance
- Are read queries using `.AsNoTracking()`?
- Are projections used (`.Select()`) instead of loading full entities to read a few fields?
- Are collection endpoints paginated?
- Is there risk of N+1 queries?
- Are bulk operations using `ExecuteUpdateAsync` / `ExecuteDeleteAsync` instead of loading entities?
- Is `.ToList()` called eagerly where it shouldn't be?

### Memory leaks and resource management
- Is `new HttpClient()` used anywhere? (socket exhaustion) → must use `IHttpClientFactory`
- Are `IDisposable` / `IAsyncDisposable` objects wrapped in `using`?
- Is `async void` used outside of event handlers?
- Are event subscriptions cleaned up in `Dispose`?
- Is `DbContext` being held open longer than a single operation scope?
- Are closures capturing `this` or large objects in long-lived callbacks?

### Concurrency and DI lifetime
- Is a `Scoped` service being injected into a `Singleton`? (captive dependency)
- Is `DbContext` injected directly into a `Singleton`?
- Is shared mutable state accessed from multiple threads without synchronization?
- Is `.Result` or `.Wait()` called on async code (deadlock risk)?

### Security
- Are there hardcoded secrets, credentials, tokens or internal URLs?
- Are new endpoints protected with appropriate authorization policies?
- Is user input validated at the API boundary before being processed?
- Are internal database IDs exposed in the API response?
- Is sensitive data being logged (passwords, tokens, PII)?

### Naming and conventions
- Do all async methods have the `Async` suffix?
- Are DTOs named `XRequest` / `XResponse`?
- Are constants used instead of hardcoded strings (except log messages)?
- Is the code in English?

### Null safety
- Are there `null` returns from services instead of `Result<T>` or exceptions?
- Are nullable warnings suppressed with `!` without justification?
- Do collection-returning methods return empty collections instead of `null`?

### Tests
- Is there new business logic without corresponding unit tests?
- Do tests follow AAA with explicit `// Arrange`, `// Act`, `// Assert` sections?
- Are all critical paths covered: happy path, expected errors, edge cases?
- Are mocks used for external dependencies?

### Configuration and environment
- Were new environment variables or `appsettings` keys added?
  - Are they documented in `README.md`?
  - Are they in `.env.example` if the project uses Docker?
  - Are they validated at startup with `ValidateOnStart()`?
- Was the Options pattern used — not raw `IConfiguration` in services?

### Docker (if docker-compose was modified)
- Does every service have a `healthcheck` defined?
- Does every service have a `restart` policy?
- Do services use `depends_on` with `condition: service_healthy` for their dependencies?
- Are secrets coming from `.env` and not hardcoded in the compose file?

### Documentation
- If the change affects architecture or a significant design decision — was an ADR created in `/docs/adr/`?
- If the change adds/modifies configuration, endpoints or deployment — was `README.md` updated?

---

## Step 3 — Output format

Group findings by severity. Only include sections that have findings.

```
## Code Review

### 🔴 Blockers
Issues that must be resolved before merging (security, correctness, memory leaks, captive dependencies).
- [file:line] Description of the problem and why it matters

### 🟡 Improvements
Violations of standards or patterns that should be addressed soon.
- [file:line] Description and suggested fix

### 🔵 Suggestions
Non-urgent observations, style, or opportunities to improve quality.
- [file:line] Description

### ⚠️ Refactor opportunities (out of scope)
Problems detected in existing code not touched by this PR — for the backlog.
- [file] [CRÍTICO / MEJORA / TÉCNICO] Description

### ℹ️ Notices
- New environment variables added: [list them]
- New appsettings keys added: [list them]
- README updated: yes / no / not required
- ADR created: yes / no / not required
- Tests added: yes / no / not required
```

Close with one of:
- ✅ **Ready to merge** — no blockers found
- ⚠️ **Merge with caution** — improvements recommended but no blockers
- 🚫 **Do not merge** — blockers must be resolved first

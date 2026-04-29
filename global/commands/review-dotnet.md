# Full code review

Perform a comprehensive review of all changes in the current branch. Apply every expert lens available: correctness, architecture, concurrency, performance, security, domain modeling, and operational readiness.

---

## Step 0 — Load project context first

**Read `CLAUDE.md` before reviewing a single line of code.**

Extract and hold in mind:
- The actual architecture (Clean Architecture, 3-layer, modular monolith, microservice — whatever it is)
- Layer names and their responsibilities as the project defines them
- Error handling strategy (`Result<T>`, exceptions, or both)
- DI conventions and lifetimes used
- Naming conventions for DTOs, services, repositories
- Whether CQRS/MediatR is in use
- Whether domain events, value objects, or aggregates are used

**The golden rule: every finding must be evaluated against what THIS project is, not against an imagined ideal.** If the project has no domain layer, do not report missing value objects. If it uses 3-layer architecture, do not report missing CQRS handlers. Adapt every dimension to what CLAUDE.md describes.

Then collect the diff:
```bash
git diff main...HEAD
git diff main...HEAD --stat
git log main...HEAD --oneline
```

---

## Step 1 — Review across all dimensions

Apply every dimension below. Skip dimensions that are not applicable to the changed files — but never skip a dimension just because the project is simple. A 3-layer project still has concurrency risks.

---

### Correctness and business logic

- Does the change implement the intended behavior correctly?
- Are business rules enforced in the right layer (per CLAUDE.md — not per an assumed ideal)?
- Are edge cases handled: null inputs, empty collections, boundary values, missing entities?
- Does the change silently alter behavior in code paths not directly modified?
- Are all code paths that lead to state mutations guarded by appropriate preconditions?

---

### Architecture and layer boundaries

Evaluate strictly against the architecture described in CLAUDE.md — nothing else.

- Do dependencies flow in the direction CLAUDE.md defines?
- Does each class have a single, clear responsibility?
- Is there business logic where there should not be (controllers, middleware, infrastructure, mappers)?
- Are there abstractions (interfaces) for all external dependencies — no `new` for services?
- Are new behaviors added by extension, not by modifying unrelated existing classes?
- Is infrastructure knowledge leaking upward (EF types, HTTP clients, external DTOs in domain/application)?

If the project uses Clean Architecture:
- Does Domain reference any other project? (must not)
- Does Application reference Infrastructure? (must not)
- Does Infrastructure reference API? (must not)

If the project uses simple 3-layer (Controllers → Services → Repositories):
- Is logic in services, not controllers?
- Are repositories behind interfaces?

---

### Concurrency and async correctness

These apply to every project regardless of architecture. Concurrency bugs are silent and catastrophic.

**Async/await:**
- `async void` outside event handlers — unobservable exceptions, process crash
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` — deadlock risk in ASP.NET context
- `await` missing on async calls — fire-and-forget without intent, swallowed exceptions
- `async` method that never awaits — unnecessary state machine allocation
- `CancellationToken` not propagated through the call chain — operations cannot be cancelled

**Shared state and DI lifetimes:**
- `Scoped` service injected into `Singleton` — captive dependency; effectively a singleton shared across requests
- `DbContext` injected directly into a `Singleton` — not thread-safe; corrupts state under concurrency
- `static` mutable fields — shared across all requests; any write is a race condition
- Instance fields on Scoped services accessed from background threads — scope boundary violation
- `Transient IDisposable` inside `Singleton` — never released; memory leak

**Locking:**
- `lock` on `this` or a public object — external code can deadlock it
- `SemaphoreSlim` without `Release()` in `finally` — deadlock on exception
- Nested locks acquired in inconsistent order — deadlock under concurrent execution
- `lock` around async code or `await` inside `lock` — compile error or thread starvation

**Background services:**
- `ExecuteAsync` not catching exceptions — service dies silently
- `stoppingToken` not respected — process hangs on shutdown
- Shared `DbContext` constructed at Singleton scope — use `IServiceScopeFactory` per operation
- Non-idempotent background job — double-execution on crash causes data corruption

**Entity Framework:**
- `DbContext` shared across threads — not thread-safe
- Concurrent `SaveChangesAsync()` calls on the same context instance
- Missing optimistic concurrency (`RowVersion`) on entities written from multiple sources

---

### Performance and resource efficiency

**Database queries (if project uses an ORM):**
- Missing `.AsNoTracking()` on read-only queries — EF tracks entities with no benefit
- Full entity loaded when only 2–3 fields are used — missing `.Select()` projection
- N+1 risk: navigation property accessed in a loop without `.Include()` or explicit join
- Lazy loading enabled — triggers N+1 silently
- Collection endpoint without pagination — unbounded result set
- `.Contains(list)` with a list that grows — degrades to full scan; consider restructuring
- Multiple `SaveChangesAsync()` calls in one request — batch into one

**Memory allocations:**
- `string +=` in a loop — O(n²); use `StringBuilder` or `string.Create()`
- `new HttpClient()` — socket exhaustion; must use `IHttpClientFactory`
- `IDisposable` / `IAsyncDisposable` not wrapped in `using` — resource leak
- `.ToList()` or `.ToArray()` called eagerly on a large sequence before filtering
- Closures capturing large objects or `this` in long-lived callbacks — GC roots
- `params object[]` in high-frequency logging — use `[LoggerMessage]` source generator or structured overloads
- Large arrays allocated per-request — use `ArrayPool<T>.Shared`

**I/O efficiency:**
- Independent async operations called sequentially — use `Task.WhenAll` to parallelize
- Large HTTP responses read with `GetStringAsync()` — use `GetStreamAsync()` + streaming deserialization
- `CancellationToken` not forwarded — aborted requests continue consuming DB connections and threads

---

### Security

- Hardcoded credentials, tokens, connection strings, or internal URLs anywhere in code
- New endpoints without authorization — missing `[Authorize]` or policy
- User input not validated at the system boundary before processing
- Internal database IDs exposed in API responses — use GUIDs or obfuscated IDs
- Sensitive data logged: passwords, tokens, PII, session data
- SQL injection risk: raw SQL with string concatenation instead of parameterized queries
- Mass assignment: entity properties bound directly from request without explicit allowlist
- CORS policy too permissive for the environment

---

### Domain model (only if the project has a domain layer or uses DDD patterns)

Skip this section entirely if CLAUDE.md describes a simple CRUD service with no domain layer.

- Can an entity be created in an invalid state (parameterless constructor + public setters)?
- Are invariants enforced inside the entity/aggregate, or only in the service layer?
- Are there concepts expressed as raw primitives that have business rules (email, money, status, ID)?
- Are collections on entities exposed as `IReadOnlyList<T>` — no external `Add`/`Remove`?
- Are object references used between aggregates instead of IDs?
- Are domain events raised by the aggregate, not by the application service?
- Is business logic duplicated across services that belongs on the entity?

---

### Design and maintainability

- Long methods (> 20 lines): is there extractable logic with a meaningful name?
- Long parameter lists (> 3 params): should these be grouped into a parameter object?
- Nested conditionals (> 2 levels): can guard clauses flatten this?
- Duplicated logic across classes: extract to a shared location?
- `if/else if` chains on type or status: consider Strategy, polymorphism, or `switch` expression
- Magic numbers or strings in code: use named constants
- Naming: do identifiers express intent clearly in the domain language?
- All identifiers, comments, and code in English?

---

### Null safety

- Services returning `null` to signal "not found" — use `Result<T>` or throw a domain exception (per project convention in CLAUDE.md)
- Nullable reference warnings suppressed with `!` without an explanatory comment
- Collection-returning methods returning `null` instead of empty collection
- Nullable types used where the value should always be present — missing guard clause

---

### Tests

- New business logic, handlers, or services without unit tests
- Tests not following AAA with explicit `// Arrange`, `// Act`, `// Assert` sections
- Critical paths missing: happy path, not-found, validation failure, business rule violation
- External dependencies not mocked — tests hitting real DB or HTTP without intent
- Tests asserting on internal implementation instead of observable behavior
- Multiple unrelated assertions in a single test

---

### Configuration and environment

- New `appsettings` keys or environment variables added?
  - Documented in `README.md`?
  - In `.env.example` if project uses Docker?
  - Validated at startup with `ValidateOnStart()`?
- Raw `IConfiguration` used in a service instead of the Options pattern?

---

### Docker (only if `Dockerfile` or `docker-compose.yml` was modified)

- Every service has a `healthcheck`?
- Every service has a `restart` policy?
- `depends_on` uses `condition: service_healthy` for dependent services?
- No secrets hardcoded — all from `.env`?

---

### Documentation and traceability

- Change affects architecture or a significant design decision → ADR created in `/docs/adr/`?
- Change adds/modifies configuration, endpoints, or deployment → `README.md` updated?
- New technical debt introduced → `docs/PROJECT_STATUS.md` updated?

---

## Step 2 — Output format

Group all findings by severity. Include only sections that have findings — never include an empty section.

```
## Revisión de código — [nombre del branch o feature]

### 🔴 Bloqueantes
Deben resolverse antes del merge: bugs de concurrencia, pérdida de datos, problemas de seguridad,
memory leaks, captive dependencies, comportamiento incorrecto.

- **[archivo:línea]** `[dimensión]` — descripción del problema
  - *Por qué importa:* consecuencia concreta en producción
  - *Fix:* cambio exacto o patrón correcto (con código si aplica)

### 🟡 Mejoras
Violaciones de estándares o diseño deficiente que deben corregirse pronto — no bloquean el merge
pero generan deuda real.

- **[archivo:línea]** `[dimensión]` — descripción
  - *Corrección sugerida:* solución concreta

### 🔵 Sugerencias
Observaciones de calidad, estilo u oportunidades de mejora no urgentes.

- **[archivo:línea]** — descripción

### ⚠️ Oportunidades de refactor (fuera del alcance de este PR)
Problemas encontrados en código existente NO modificado por este PR. Para el backlog.

- **[archivo]** `[CRITICAL / IMPROVEMENT / TECHNICAL]` — descripción

### ℹ️ Avisos
- Variables de entorno nuevas: [listar / ninguna]
- Claves nuevas en appsettings: [listar / ninguna]
- Migraciones de BD incluidas: [sí / no]
- README actualizado: [sí / no / no aplica]
- ADR creado: [sí / no / no aplica]
- Tests agregados: [sí / no]
- PROJECT_STATUS.md actualizado: [sí / no / no aplica]
```

Cerrar con una de estas tres:
- ✅ **Listo para merge** — sin bloqueantes
- ⚠️ **Merge con precaución** — mejoras recomendadas pero sin bloqueantes
- 🚫 **No hacer merge** — bloqueantes deben resolverse primero

---

## Output rules

- Every finding must reference a specific file and line — no vague "there is a concurrency issue in the service"
- Every 🔴 finding must include the concrete production consequence and a specific fix
- Adapt every dimension to the architecture in CLAUDE.md — never penalize a project for not having a pattern it never claimed to have
- If a dimension was checked and found clean, do not mention it — only report findings
- If a section (🔴, 🟡, 🔵) has no findings, omit it entirely from the output
- Be direct: "this deadlocks when X and Y happen simultaneously" is better than "this could potentially cause issues"

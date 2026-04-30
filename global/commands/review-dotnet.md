# Full code review

Perform a comprehensive review of all changes in the current branch. Apply every expert lens available: correctness, architecture, concurrency, performance, security, domain modeling, and operational readiness.

---

## Step 0 — Load project context first

**Read `CLAUDE.md` before reviewing a single line of code.**

Extract and hold in mind:
- Architecture (Clean Architecture, 3-layer, modular monolith, microservice)
- Layer names and their responsibilities as the project defines them
- Error handling strategy (`Result<T>`, exceptions, or both)
- DI conventions and lifetimes used
- Whether CQRS/MediatR is in use
- Whether domain events, value objects, or aggregates are used

**Golden rule: every finding must be evaluated against THIS project, not against an imagined ideal.**

Then collect the diff:
```bash
git diff main...HEAD
git diff main...HEAD --stat
git log main...HEAD --oneline
```

---

## Step 1 — Review across all dimensions

Skip dimensions not applicable to the changed files — but never skip a dimension just because the project is simple.

---

### Correctness and business logic

- Does the change implement the intended behavior correctly?
- Are business rules enforced in the right layer (per CLAUDE.md)?
- Are edge cases handled: null inputs, empty collections, boundary values, missing entities?
- Does the change silently alter behavior in code paths not directly modified?
- Are all code paths leading to state mutations guarded by appropriate preconditions?

---

### Architecture and layer boundaries

Evaluate strictly against the architecture in CLAUDE.md — nothing else.

- Do dependencies flow in the direction CLAUDE.md defines?
- Is there business logic in controllers, middleware, infrastructure, or mappers?
- Are there abstractions (interfaces) for all external dependencies — no `new` for services?
- Is infrastructure knowledge leaking upward (EF types, HTTP clients, external DTOs in domain/application)?

If Clean Architecture:
- Does Domain reference any other project? (must not)
- Does Application reference Infrastructure? (must not)
- Does Infrastructure reference API? (must not)

---

### Concurrency and async correctness

**These apply to every project regardless of architecture. Concurrency bugs are silent and catastrophic.**

**DI lifetime violations:**
- `Scoped` service injected into `Singleton` — captive dependency, effectively shared across requests
- `DbContext` injected directly into `Singleton` — not thread-safe, corrupts state under concurrency
- `static` mutable fields — shared across all requests, any write is a race condition
- `Transient IDisposable` inside `Singleton` — never released, memory leak

**Async/await:**
- `async void` outside event handlers — unobservable exceptions, process crash
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` — deadlock risk in ASP.NET context
- `CancellationToken` not propagated through the call chain

**Locking:**
- `lock` on `this` or a public object — external code can deadlock it
- `SemaphoreSlim` without `Release()` in `finally` — deadlock on exception
- Nested locks acquired in inconsistent order
- `await` inside `lock` — compile error or thread starvation

**Background services:**
- `ExecuteAsync` not catching exceptions — service dies silently
- `stoppingToken` not respected — process hangs on shutdown
- Shared `DbContext` at Singleton scope — use `IServiceScopeFactory` per operation
- Non-idempotent job — double-execution on crash causes data corruption

---

### Performance and resource efficiency

**Database (EF Core):**
- Missing `.AsNoTracking()` on read-only queries
- Full entity loaded when only a few fields needed — missing `.Select()` projection
- N+1 risk: navigation property accessed in a loop without `.Include()`
- Collection endpoint without pagination — unbounded result set
- Multiple `SaveChangesAsync()` in one request — batch into one

**Memory and I/O:**
- `params object[]` in high-frequency logging — use `[LoggerMessage]` source generator
- Large arrays allocated per-request — use `ArrayPool<T>.Shared`
- Independent async operations called sequentially — use `Task.WhenAll`
- Large HTTP responses with `GetStringAsync()` — use `GetStreamAsync()` + streaming deserialization

---

### Security

- Hardcoded credentials, tokens, connection strings, or internal URLs
- New endpoints without `[Authorize]` or policy
- User input not validated at the system boundary
- Internal database IDs exposed in API responses — use GUIDs or obfuscated IDs
- Mass assignment: entity properties bound directly from request without explicit allowlist
- CORS policy too permissive for the environment

---

### Domain model (only if project has a domain layer)

Skip entirely if CLAUDE.md describes a simple CRUD service with no domain layer.

- Can an entity be created in an invalid state (parameterless constructor + public setters)?
- Are invariants enforced inside the entity/aggregate, not in the service?
- Are collections on entities exposed as `IReadOnlyList<T>`?
- Are object references used between aggregates instead of IDs?
- Is business logic duplicated across services that belongs on the entity?

---

### Design and maintainability

- Long methods (> 20 lines), long parameter lists (> 3), nested conditionals (> 2 levels)
- `if/else if` chains on type or status — consider Strategy or `switch` expression
- Duplicated logic across classes
- Magic numbers or strings — use named constants
- Naming: do identifiers express intent in the domain language?
- All identifiers, comments, and code in English?

---

### Null safety

- Services returning `null` to signal "not found" — use `Result<T>` or domain exception
- Nullable warnings suppressed with `!` without explanatory comment
- Collection-returning methods returning `null`

---

### Tests

- New business logic, handlers, or services without unit tests
- Tests missing explicit `// Arrange`, `// Act`, `// Assert` sections
- External dependencies not mocked — tests hitting real DB or HTTP without intent
- Tests asserting on internal implementation instead of observable behavior
- Multiple unrelated assertions in a single test

---

### Configuration and environment

- New `appsettings` keys or env vars: documented in README? In `.env.example`? Validated at startup with `ValidateOnStart()`?
- Raw `IConfiguration` used in a service instead of the Options pattern?

---

### Docker (only if `Dockerfile` or `docker-compose.yml` modified)

- Every service has `healthcheck` and `restart` policy?
- `depends_on` uses `condition: service_healthy` for dependent services?
- No secrets hardcoded — all from `.env`?

---

### Observability — metrics (only if project uses Prometheus / OpenTelemetry Metrics)

**Detect:** look for `prometheus-net`, `OpenTelemetry.Metrics`, `Meter`, `Counter<T>`, `Histogram<T>` in `.csproj` or DI registration. **Skip entirely if absent.**

**Coverage gaps:**
- New endpoint or operation without a request counter or duration histogram
- New background job without execution counter, error counter, and processing duration
- New external integration without a latency histogram and error counter
- Business-critical operation without a business metric

**Correctness:**
- Counter incremented in `catch` but not on success path — or vice versa
- Labels with unbounded cardinality: user ID, email — destroys Prometheus memory
- Metric recorded before the operation completes
- Exception paths that exit without recording the metric

**Naming:**
- `snake_case` with `_total` (counters), `_seconds` (durations), `_bytes` (sizes)
- Inconsistent label names across related metrics in the same service
- New metric without a description string

**Alertability:**
- Error counter without a corresponding total counter — can't derive error rate
- Duration histogram without appropriate bucket boundaries for expected latency

---

### Documentation and traceability

- Architecture or significant design decision → ADR in `/docs/adr/`?
- Change affects configuration, endpoints, or deployment → README updated?
- New technical debt → `docs/PROJECT_STATUS.md` updated?
- New metrics → documented (name, labels, meaning, alert thresholds)?

---

## Step 2 — Output format

Group findings by severity. Include only sections with findings — never include an empty section.

```
## Revisión de código — [nombre del branch o feature]

### 🔴 Bloqueantes
Deben resolverse antes del merge: bugs de concurrencia, pérdida de datos, seguridad,
memory leaks, captive dependencies, comportamiento incorrecto.

- **[archivo:línea]** `[dimensión]` — descripción del problema
  - *Por qué importa:* consecuencia concreta en producción
  - *Fix:* cambio exacto o patrón correcto (con código si aplica)

### 🟡 Mejoras
Violaciones de estándares o diseño deficiente — no bloquean el merge pero generan deuda real.

- **[archivo:línea]** `[dimensión]` — descripción
  - *Corrección sugerida:* solución concreta

### 🔵 Sugerencias
Observaciones de calidad, estilo u oportunidades de mejora no urgentes.

- **[archivo:línea]** — descripción

### ⚠️ Oportunidades de refactor (fuera del alcance de este PR)
Problemas en código existente NO modificado por este PR. Para el backlog.

- **[archivo]** `[CRITICAL / IMPROVEMENT / TECHNICAL]` — descripción

### ℹ️ Avisos
- Variables de entorno nuevas: [listar / ninguna]
- Claves nuevas en appsettings: [listar / ninguna]
- Migraciones de BD incluidas: [sí / no]
- README actualizado: [sí / no / no aplica]
- ADR creado: [sí / no / no aplica]
- Tests agregados: [sí / no]
- PROJECT_STATUS.md actualizado: [sí / no / no aplica]
- Métricas nuevas: [listar nombre + labels / ninguna / no aplica]
- Gaps de métricas detectados: [sí — ver hallazgos / no / no aplica]
```

Cerrar con una de estas tres:
- ✅ **Listo para merge** — sin bloqueantes
- ⚠️ **Merge con precaución** — mejoras recomendadas pero sin bloqueantes
- 🚫 **No hacer merge** — bloqueantes deben resolverse primero

---

## Output rules

- Every finding must reference a specific file and line — no vague "there is a concurrency issue in the service"
- Every 🔴 finding must include the concrete production consequence and a specific fix
- Adapt every dimension to the architecture in CLAUDE.md — never penalize for patterns the project never claimed to have
- If a dimension was checked and found clean, do not mention it
- If a section has no findings, omit it entirely
- Be direct: "this deadlocks when X and Y happen simultaneously" beats "this could potentially cause issues"

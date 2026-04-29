# Performance & Memory Engineering

Act as a senior .NET performance engineer. Analyze code for memory allocation, GC pressure, I/O efficiency, and CPU hot paths. Focus on measurable, production-relevant impact — not micro-optimizations that don't matter at real scale.

**Usage:**
- `/user:performance-dotnet` — analyze all changes in the current branch
- `/user:performance-dotnet <file, service, or endpoint>` — targeted analysis

## $ARGUMENTS

---

## Step 1 — Collect the code

If `$ARGUMENTS` specifies a target:
- Read the specified files
- Read callers if it's a service or method to understand the call frequency

If `$ARGUMENTS` is empty:
```bash
git diff main...HEAD
git diff main...HEAD --stat
```

Read `CLAUDE.md` for stack context — ORM, caching, DI lifetimes.

---

## Step 2 — Analyze across all performance dimensions

### Memory allocations and GC pressure

**String operations:**
- `string +=` in a loop — O(n²) allocations; use `StringBuilder` or `string.Create()`
- `string.Format` / interpolation in hot paths — allocates; use `ValueStringBuilder` or logging with structured args
- `.ToString()` called repeatedly on the same value — cache the result
- `string.Split()` returning arrays — prefer `MemoryExtensions.Split()` (Span-based, allocation-free)

**LINQ in hot paths:**
- `.ToList()` / `.ToArray()` called eagerly on large sequences — forces full materialization before filtering
- `.Where().First()` vs `.FirstOrDefault(condition)` — extra enumeration
- `.Count() > 0` vs `.Any()` — enumerates needlessly
- Chained LINQ on IQueryable that materializes mid-chain — defeats query composition
- `.OrderBy()` on large in-memory collections in every request — sort once and cache, or sort at the DB

**Unnecessary allocations:**
- `new List<T>()` / `new Dictionary<TK,TV>()` inside hot loops — reuse or pool
- Boxing: value types assigned to `object`, `IComparable`, non-generic interfaces in hot paths
- Closures in hot paths: lambda capturing outer variables forces heap allocation
- `params object[]` in logging calls — use structured logging overloads or `[LoggerMessage]`
- `async` state machine allocation on every call — consider `ValueTask` for methods that complete synchronously in the common case

**Object pooling and reuse:**
- `new HttpClient()` — socket exhaustion + overhead; must use `IHttpClientFactory`
- `new MemoryStream()` for serialization — use `RecyclableMemoryStream` or `ArrayPool<byte>`
- Large arrays allocated per-request — use `ArrayPool<T>.Shared.Rent()`
- `StringBuilder` created per-operation — pool with `ObjectPool<StringBuilder>`

### Entity Framework and database

**N+1 queries:**
- `.Include()` missing on navigation properties accessed in a loop — one query per entity
- Lazy loading enabled — triggers N+1 silently; disable and use explicit `.Include()`
- Calling `.Single()` or `.First()` inside `foreach` on a list — query per iteration

**Data transfer volume:**
- `SELECT *` (loading full entity) when only 2–3 fields are needed — use `.Select()` projection
- No `.AsNoTracking()` on read-only queries — EF tracks changes for no reason; CPU + memory waste
- Loading large collections without pagination — returns unbounded rows to the application

**Query efficiency:**
- Missing index on filtered/sorted columns — full table scan at scale
- `.Contains(list)` with large lists — generates `IN (...)` with hundreds of values; consider temp table join
- `DateTime` operations in predicates that prevent index use (e.g., `DbFunctions.DateDiffDay`)
- Calling `.Count()` when only existence check is needed — use `.Any()`

**Connection and context:**
- `DbContext` lifetime too long — holds DB connection open; use Scoped, not Singleton
- Multiple `SaveChangesAsync()` calls in one request — batch into one
- `ExecuteUpdateAsync` / `ExecuteDeleteAsync` for bulk ops — never load entities just to delete/update in bulk

### I/O and async efficiency

- Synchronous I/O on async thread (blocking reads/writes) — wastes threadpool threads under load
- `await Task.WhenAll()` not used when multiple independent async operations can run in parallel
- Sequential `await` calls to independent external services — parallelize with `Task.WhenAll`
- Missing `CancellationToken` — requests that are cancelled by the client continue consuming resources
- `HttpClient.GetStringAsync()` for large payloads — use streaming with `GetStreamAsync()` + `ReadAsStreamAsync()`
- JSON serialization of full object graphs when only a subset is needed — project before serializing

### Caching

- Expensive computation repeated on every request with identical input — cache with `IMemoryCache` or `IDistributedCache`
- Cache without expiration — stale data permanently; always set `AbsoluteExpiration` or `SlidingExpiration`
- Cache stampede: many requests computing the same value simultaneously on cache miss — use `SemaphoreSlim`-guarded initialization or `GetOrCreateAsync`
- Caching entities with navigation properties — bloated cache entries; cache DTOs/projections
- No cache eviction on write — reads stale data after updates

### CPU hot paths

- `Regex` compiled per-call — use `static readonly Regex` with `RegexOptions.Compiled`, or source generators
- `Enum.Parse` / `Enum.GetName` in hot paths — cache results in a `Dictionary`
- `DateTime.Now` in tight loops — cache once per iteration; `UtcNow` is faster than `Now`
- `Guid.NewGuid()` per loop iteration when not needed — generate once
- Deep call stacks in synchronous hot paths — profile with `dotnet-trace` / `BenchmarkDotNet`

---

## Step 3 — Output format

```
## Análisis de performance

### 🔴 Problemas críticos
Impactan directamente en latencia, throughput o memoria bajo carga de producción.

- **[archivo:línea]** — [descripción]
  - *Impacto estimado:* [qué se degrada y a partir de qué escala]
  - *Fix:* [código corregido o patrón específico]

### 🟡 Ineficiencias significativas
Funcionan pero generan overhead innecesario que se acumula bajo carga.

- **[archivo:línea]** — [descripción]
  - *Por qué importa:* [GC pressure, allocations extra, latencia adicional]
  - *Fix recomendado:* [solución]

### 🔵 Micro-optimizaciones
Mejoras menores con impacto bajo pero que suman en código de alta frecuencia.

- **[archivo:línea]** — [descripción]

### Herramientas recomendadas para validar
[Solo las que aplican al código analizado]
- `BenchmarkDotNet` para: [qué medir exactamente]
- `dotnet-trace` / `dotnet-counters` para: [qué observar]
- EF Core logging (`EnableSensitiveDataLogging`) para: [qué queries revisar]

### Resumen
- Problemas críticos: N
- Allocations evitables por request: [estimación si es posible]
- Cambio de mayor impacto: [la optimización con mayor ROI]
```

---

## Output rules

- Quantify impact where possible: "this allocates a new array on every request" > "this is inefficient"
- Distinguish hot paths (called thousands of times per second) from cold paths (startup, admin endpoints) — optimize the former, not the latter
- Never recommend micro-optimizations for code that runs once at startup or rarely
- If the code is already optimal, confirm it explicitly so the dev knows it was checked
- For every critical finding, provide the corrected code snippet

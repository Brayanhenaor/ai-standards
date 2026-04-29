# Concurrency & Async Expert Review

Act as a senior .NET concurrency engineer. Analyze code for correctness under concurrent execution — not just happy-path correctness, but correctness when multiple threads, tasks, or requests execute simultaneously.

**Usage:**
- `/user:concurrency-dotnet` — review all changes in the current branch
- `/user:concurrency-dotnet <file or feature area>` — targeted review

## $ARGUMENTS

---

## Step 1 — Collect the code

If `$ARGUMENTS` specifies a file or area:
```bash
# Read the specified files
git diff main...HEAD -- <path>   # or just read the files directly
```

If `$ARGUMENTS` is empty:
```bash
git diff main...HEAD
git diff main...HEAD --stat
```

Also read `CLAUDE.md` for DI lifetime configuration — captive dependency bugs are concurrency bugs.

---

## Step 2 — Analyze across all concurrency dimensions

### Async/await correctness
- `async void` outside event handlers — exceptions are unobservable, crashes the process
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` — deadlocks in synchronization-context environments (ASP.NET, Blazor)
- `Task.Run(() => asyncMethod().Result)` — disguised sync-over-async
- Missing `await` on async calls — fire-and-forget without intent; exceptions swallowed
- `async` method that never actually awaits — useless state machine allocation
- Missing `CancellationToken` propagation — operations that cannot be cancelled under load
- `ConfigureAwait(false)` — needed in library code; unnecessary but harmless in ASP.NET Core

### Shared mutable state
- `static` mutable fields — shared across all requests; any write is a race condition
- Singleton services with mutable fields — same problem as static; thread safety required
- Instance fields on services registered as Scoped used from background threads — scope boundary violations
- `Dictionary`, `List`, `HashSet` mutated from concurrent code without synchronization
- Lazy initialization without `LazyThreadSafetyMode` or `Lazy<T>` — double initialization risk

### DI lifetime bugs (captive dependency)
- `Scoped` service injected into `Singleton` — the scoped service becomes effectively a singleton, sharing state across requests
- `DbContext` in a `Singleton` — DbContext is not thread-safe; concurrent access causes data corruption or exceptions
- `Transient IDisposable` inside `Singleton` — never disposed; memory leak
- `IHttpContextAccessor` in a `Singleton` — HttpContext is per-request; wrong data under concurrency

### Lock and synchronization patterns
- `lock` on `this` or a public object — external code can deadlock the lock
- `lock` around async code — `await` inside `lock` is illegal (compile error) and `lock` held across awaits starves threads
- `SemaphoreSlim` without `Release()` in `finally` — semaphore never released; deadlock
- `Monitor.Enter` without `Monitor.Exit` in `finally` — same issue
- Nested locks in inconsistent acquisition order — deadlock under concurrent execution
- Using `lock` where `Interlocked` suffices — unnecessary contention for simple counters/flags

### Producer-consumer and channels
- `BlockingCollection` — blocks threads; prefer `Channel<T>` in async code
- Unbounded `Channel.CreateUnbounded<T>()` without backpressure — memory grows unbounded under load
- `ChannelWriter` not completing on shutdown — consumers never exit
- Multiple writers to a single-writer channel — undefined behavior

### Entity Framework concurrency
- Concurrent writes to the same entity without optimistic concurrency (`RowVersion` / `[Timestamp]`) — last write wins silently
- `DbContext` shared across threads — not thread-safe; runtime exception or data corruption
- `DbContext` used inside `Parallel.ForEach` — creates race condition on context internals
- `SaveChangesAsync()` called from multiple tasks on same context — concurrent modification

### Background services (IHostedService / BackgroundService)
- `ExecuteAsync` not catching exceptions — unhandled exception stops the service silently in some versions
- No graceful shutdown: ignoring `stoppingToken` — process hangs on SIGTERM
- Background service sharing `DbContext` injected via constructor — wrong lifetime; use `IServiceScopeFactory`
- `Timer` callback not idempotent — if previous execution is still running when timer fires, overlap causes double-processing

### Collections and data structures
- `List<T>` / `Dictionary<TK,TV>` mutated from multiple threads — undefined behavior, possible infinite loops
- `ConcurrentDictionary.GetOrAdd(key, valueFactory)` — factory may run multiple times; use only for idempotent factories
- `IEnumerable` iterated while collection is modified — `InvalidOperationException` at runtime

---

## Step 3 — Output format

```
## Análisis de concurrencia

### 🔴 Bugs críticos
Fallos que ocurren bajo carga concurrente: deadlocks, corrupción de datos, crashes silenciosos.

- **[archivo:línea]** — [descripción del bug]
  - *Escenario de fallo:* [cuándo y cómo se manifiesta]
  - *Fix:* [cambio exacto con código si aplica]

### 🟡 Riesgos latentes
Código que funciona en dev/staging pero falla bajo carga o en condiciones de carrera menos frecuentes.

- **[archivo:línea]** — [descripción]
  - *Condición de activación:* [qué tiene que pasar para que falle]
  - *Fix recomendado:* [solución]

### 🔵 Mejoras de robustez
Código correcto pero que puede mejorarse para mayor resiliencia o rendimiento bajo concurrencia.

- **[archivo:línea]** — [descripción y mejora sugerida]

### Patrones recomendados para este código
[Solo los que aplican directamente: Channel<T>, SemaphoreSlim, Interlocked, IAsyncEnumerable,
optimistic concurrency con RowVersion, IServiceScopeFactory para background services, etc.]

### Resumen
- Bugs críticos: N
- Riesgos latentes: N
- Cambio de mayor impacto: [el fix más importante con mayor ROI]
```

---

## Output rules

- Every finding must include the specific line or class — no vague "you have a concurrency issue in the service layer"
- Show the broken scenario, not just the rule violation — "this deadlocks when X and Y happen simultaneously"
- Provide the corrected code snippet for every critical finding
- If a pattern is correct, say so — confirm thread-safe usage so the dev knows what is solid

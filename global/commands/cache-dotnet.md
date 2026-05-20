# Caching patterns expert

Review or design caching strategy for the current feature. Apply the lens of a performance engineer specializing in IMemoryCache, IDistributedCache, StackExchange.Redis, and .NET 9 HybridCache. Covers: when to cache, invalidation, stampede protection, key design, serialization, and observability.

**Usage:**
- `/user:cache-dotnet` — review caching code in current branch
- `/user:cache-dotnet [feature description]` — design caching for a new feature
- `/user:cache-dotnet [service or method]` — audit a specific caching implementation

---

## Step 0 — Load context

Read `CLAUDE.md` first. Extract:
- Cache infrastructure (`IMemoryCache`, `IDistributedCache`, `HybridCache`, StackExchange.Redis)
- Registration patterns (`AddMemoryCache`, `AddStackExchangeRedisCache`)
- Existing key naming conventions

Then examine changed files:
```bash
git diff main...HEAD --stat
git diff main...HEAD -- "**/*Cache*.cs" "**/*Repository*.cs" "**/*Service*.cs"
```

---

## Step 1 — Decision: should this be cached?

For each data access or computation in review, evaluate:

**Cache if ALL of:**
- Read frequency significantly exceeds write frequency
- Data is relatively stable (changes infrequently or is acceptable stale)
- Computation or DB query is measurably expensive
- Result is deterministic for a given key

**Do NOT cache:**
- User-specific sensitive data without explicit TTL and per-user key isolation
- Data that must always be fresh (account balances, inventory, security-critical state)
- Data that changes on every read (counters, sequences)
- Data cheaper to compute than serialize/deserialize

Detect: caching of results from queries that are already sub-millisecond on indexed columns — unnecessary overhead.

---

## Step 2 — Key design

### Naming convention

```
{service}:{entity}:{identifier}:{version}
```

Examples:
```
orders:order:550e8400-e29b-41d4-a716-446655440000:v1
products:catalog:electronics:v1
users:profile:usr_123:v1
```

Rules:
- Lowercase, colon-separated — consistent across all services
- Include `version` segment for schema-breaking changes instead of clearing all keys
- Never use user-controlled input directly in cache keys without sanitization
- Keys must be deterministic for the same logical request

### Key length

- Redis keys over 512 bytes waste memory — hash long keys: `SHA256(key).ToHex()`
- Memory cache keys can be objects (reference equality) or strings

---

## Step 3 — Patterns and implementations

### Cache-Aside (most common)

```csharp
public async Task<Order?> GetOrderAsync(Guid id, CancellationToken ct)
{
    var key = $"orders:order:{id}:v1";

    // Try cache first
    if (_cache.TryGetValue(key, out Order? cached))
        return cached;

    // Miss — fetch from DB
    var order = await _repo.GetByIdAsync(id, ct);
    if (order is null) return null;

    // Store with TTL
    _cache.Set(key, order, new MemoryCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5),
        SlidingExpiration = TimeSpan.FromMinutes(1),
        Size = 1
    });

    return order;
}
```

### IDistributedCache pattern

```csharp
public async Task<Product?> GetProductAsync(string sku, CancellationToken ct)
{
    var key = $"products:product:{sku}:v1";

    var bytes = await _cache.GetAsync(key, ct);
    if (bytes is not null)
        return JsonSerializer.Deserialize<Product>(bytes);

    var product = await _repo.GetBySkuAsync(sku, ct);
    if (product is null) return null;

    var serialized = JsonSerializer.SerializeToUtf8Bytes(product);
    await _cache.SetAsync(key, serialized, new DistributedCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
    }, ct);

    return product;
}
```

### HybridCache (.NET 9+) — preferred over manual L1+L2

```csharp
public async Task<Order?> GetOrderAsync(Guid id, CancellationToken ct)
{
    return await _hybridCache.GetOrCreateAsync(
        key: $"orders:order:{id}:v1",
        factory: async (ctx) => await _repo.GetByIdAsync(id, ctx.CancellationToken),
        options: new HybridCacheEntryOptions
        {
            Expiration = TimeSpan.FromMinutes(10),
            LocalCacheExpiration = TimeSpan.FromMinutes(1)
        },
        cancellationToken: ct);
}
```

HybridCache handles stampede protection natively — no manual locking needed.

---

## Step 4 — Cache stampede prevention

Cache stampede (thundering herd): cache miss → N concurrent requests all hit DB simultaneously.

### Without HybridCache — use SemaphoreSlim

```csharp
private static readonly ConcurrentDictionary<string, SemaphoreSlim> _locks = new();

public async Task<T?> GetOrCreateWithLockAsync<T>(string key, Func<Task<T?>> factory)
{
    if (_cache.TryGetValue(key, out T? value)) return value;

    var semaphore = _locks.GetOrAdd(key, _ => new SemaphoreSlim(1, 1));
    await semaphore.WaitAsync();
    try
    {
        // Double-check after acquiring lock
        if (_cache.TryGetValue(key, out value)) return value;

        value = await factory();
        if (value is not null)
            _cache.Set(key, value, TimeSpan.FromMinutes(5));
        return value;
    }
    finally
    {
        semaphore.Release();
        _locks.TryRemove(key, out _);
    }
}
```

**Detect violation:** multiple `if (cache miss) fetch from DB` patterns without double-check or HybridCache → 🟡 stampede risk.

---

## Step 5 — Invalidation strategies

### TTL-based (simplest, acceptable staleness)

```csharp
options.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);
// Data may be up to 5 minutes stale — acceptable for most reads
```

### Event-driven invalidation (strong consistency)

```csharp
// After write — publish event or invalidate directly
public async Task UpdateOrderAsync(UpdateOrderCommand cmd)
{
    await _repo.UpdateAsync(cmd);
    await _cache.RemoveAsync($"orders:order:{cmd.OrderId}:v1");
    // Or publish OrderUpdatedEvent for distributed invalidation
}
```

### Version-based invalidation (for schema changes)

Change key version instead of clearing individual keys:
```
orders:order:{id}:v1  →  orders:order:{id}:v2
```

All v1 keys expire via TTL. No bulk delete needed. Zero risk of thundering herd on invalidation.

### Distributed invalidation with Redis pub/sub

```csharp
// Publisher
await _redis.GetSubscriber().PublishAsync("cache:invalidate:order", orderId.ToString());

// Subscriber (in each instance)
_subscriber.Subscribe("cache:invalidate:order", (channel, orderId) =>
    _localCache.Remove($"orders:order:{orderId}:v1"));
```

---

## Step 6 — Serialization

```csharp
// BAD — BinaryFormatter is deprecated, JSON is slow for large objects
// GOOD options for Redis:

// Option 1 — System.Text.Json (default, good for most cases)
var bytes = JsonSerializer.SerializeToUtf8Bytes(value, _jsonOptions);

// Option 2 — MessagePack (30-50% smaller, 3-5x faster for large objects)
// Requires MessagePack.AspNetCoreMvcFormatter NuGet
var bytes = MessagePackSerializer.Serialize(value);
```

Use MessagePack when:
- Cached objects are large (>10KB)
- Cache deserialization appears in performance profiles
- Object is serialized/deserialized at very high frequency (>1000/sec)

---

## Step 7 — PII and sensitive data

```csharp
// NEVER cache without encryption:
// - Passwords or hashes
// - JWT tokens or session data
// - Full PII objects (name + email + phone + address together)
// - Financial account numbers

// Acceptable to cache with per-user key isolation:
// - User preferences (non-sensitive)
// - User roles and permissions (with short TTL matching token expiry)
// - Aggregated user statistics
```

TTL for permission caches must be ≤ token lifetime to avoid stale authorization.

---

## Step 8 — Distributed lock with Redis (advanced)

For operations requiring distributed mutex (not just cache):

```csharp
public async Task<bool> AcquireLockAsync(string resource, TimeSpan ttl)
{
    var key = $"lock:{resource}";
    var token = Guid.NewGuid().ToString();

    // SETNX + EXPIRE atomically via SET NX EX
    return await _database.StringSetAsync(
        key, token, ttl, When.NotExists);
}

public async Task ReleaseLockAsync(string resource, string token)
{
    // Lua script to release only if token matches (prevents releasing others' locks)
    const string script = @"
        if redis.call('get', KEYS[1]) == ARGV[1] then
            return redis.call('del', KEYS[1])
        else
            return 0
        end";
    await _database.ScriptEvaluateAsync(script, new[] { (RedisKey)$"lock:{resource}" }, new[] { (RedisValue)token });
}
```

---

## Step 9 — Observability

### Required metrics

```csharp
private static readonly Counter<long> CacheRequests =
    Metrics.CreateCounter<long>("{service}_cache_requests_total",
        tags: new[] { "key_prefix", "result" }); // result: hit | miss | error

private static readonly Histogram<double> CacheOperationDuration =
    Metrics.CreateHistogram<double>("{service}_cache_operation_seconds",
        tags: new[] { "operation" }); // operation: get | set | remove

// Usage
using var timer = CacheOperationDuration.Measure("get");
var hit = _cache.TryGetValue(key, out var value);
CacheRequests.Add(1, keyPrefix, hit ? "hit" : "miss");
```

**Target hit ratios:** >80% for stable reference data, >60% for user-specific data.

---

## Step 10 — Output format

### Review mode:

```
## Revisión de caching — [branch]

### 🔴 Bloqueantes
- **[archivo:línea]** — descripción del problema
  - *Riesgo:* impacto en producción (stampede / staleness / data leak)
  - *Fix:* corrección con código

### 🟡 Mejoras
- **[archivo:línea]** — descripción

### 🔵 Sugerencias
- **[archivo:línea]** — oportunidad de mejora

### Hit ratio estimado
[Evaluación de si el TTL y la frecuencia de acceso justifican el cache]
```

### Design mode:

```
## Diseño de cache — [feature]

### Estrategia elegida
[Cache-Aside / Write-Through / Write-Behind / HybridCache — con justificación]

### Claves de cache
[Tabla: key pattern | TTL | invalidación | justificación]

### Stampede protection
[Mecanismo: HybridCache nativo / SemaphoreSlim]

### Serialización
[System.Text.Json / MessagePack — con justificación]

### Invalidación
[TTL / event-driven / version-based — cuándo y cómo]

### Métricas
[counters e histogramas a implementar]
```

---

## Output rules

- Every 🔴 finding includes the exact failure scenario (data leak, stampede condition, or stale auth)
- PII caching without encryption always 🔴
- Stampede risk without HybridCache or double-check locking always 🟡
- Always verify cache justification — "it's faster" is not enough; estimate hit ratio
- Cross-reference with `performance-dotnet` when cache misses appear in performance findings

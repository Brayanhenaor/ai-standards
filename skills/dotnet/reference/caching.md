# Caching

## When to cache

Cache only when **all** hold: reads ≫ writes, the data tolerates staleness for the TTL, the
source is measurably expensive, and the result is deterministic per key.

**Never cache:** passwords/tokens/hashes, data that must be fresh (balances, auth/security state),
PII without per-user isolation and a TTL, or results cheaper to compute than to (de)serialize.

## Prefer HybridCache (.NET 9+)

`HybridCache` unifies in-memory + distributed (L1/L2), and handles **stampede protection** and
serialization natively — prefer it over hand-rolling `IMemoryCache`/`IDistributedCache`:

```csharp
return await hybridCache.GetOrCreateAsync(
    key, async ct => await repo.GetAsync(id, ct),
    new() { Expiration = TimeSpan.FromMinutes(5) }, cancellationToken: ct);
```

Without HybridCache, guard every cache-miss path with a `SemaphoreSlim` + double-check so N
concurrent misses don't all hit the source.

## Keys & TTL

- Key format: `{service}:{entity}:{id}:{version}` — lowercase, colon-separated. Bump the version
  segment on schema changes instead of bulk-clearing. Never embed unsanitized user input.
- Use absolute (or absolute-relative) expiration, not sliding-only, to bound growth.
- Rough TTLs: reference/lookup data hours; catalog 5–30 min; profile 5–15 min; search 1–5 min;
  permissions ≤ token lifetime; financial/real-time — don't cache.

## Invalidation & PII

- Write-heavy data: invalidate on change (`RemoveAsync` / `RemoveByTagAsync`), don't wait for TTL.
- Permission caches must expire within the token lifetime. Never cache JWTs/refresh tokens/API keys.
- Expose hit/miss/latency metrics per cache (see observability); target >80% hits for reference data.

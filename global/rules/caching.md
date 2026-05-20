---
paths:
  - "**/*Cache*.cs"
  - "**/*Repository*.cs"
alwaysApply: false
description: "Caching: when to cache, key naming, TTL guidelines, invalidation, stampede protection, PII rules"
---

# Caching standards

## When to cache

**Cache when ALL conditions apply:**
- Read frequency >> write frequency
- Data acceptable as stale for the TTL duration
- Computation or DB query is measurably expensive (>5ms or high frequency)
- Result is deterministic for a given key

**Never cache:**
- Passwords, tokens, or hashes
- Data that must always be fresh (account balances, security state)
- PII without explicit TTL and per-user key isolation
- Results cheaper to compute than to serialize/deserialize

## Key naming convention

```
{service}:{entity}:{identifier}:{version}
```

Examples:
```
orders:order:550e8400-e29b-41d4-a716-446655440000:v1
products:catalog:electronics:v1
users:permissions:usr_123:v1
```

Rules:
- Lowercase, colon-separated, no spaces
- Include version segment — increment on schema changes instead of bulk-clearing
- Never embed user-controlled input directly — sanitize first
- Redis keys over 512 bytes → hash with SHA256

## TTL guidelines

| Data type | Recommended TTL |
|-----------|----------------|
| Reference / lookup data (countries, categories) | 1–24 hours |
| Product catalog | 5–30 minutes |
| User permissions / roles | ≤ token lifetime (avoid stale auth) |
| User profile (non-sensitive) | 5–15 minutes |
| Search results | 1–5 minutes |
| Real-time or financial data | Do not cache |

Use `AbsoluteExpirationRelativeToNow` — never only `SlidingExpiration` (prevents unbounded growth).

## Stampede protection

When NOT using HybridCache, guard all cache-miss paths:

```csharp
// BAD — N concurrent misses all hit DB
if (!_cache.TryGetValue(key, out T? value))
{
    value = await _repo.GetAsync(id);
    _cache.Set(key, value, ttl);
}

// GOOD — SemaphoreSlim with double-check
await semaphore.WaitAsync();
try
{
    if (!_cache.TryGetValue(key, out value))
    {
        value = await _repo.GetAsync(id);
        _cache.Set(key, value, ttl);
    }
}
finally { semaphore.Release(); }

// BEST — HybridCache (.NET 9+) handles this natively
return await _hybridCache.GetOrCreateAsync(key, factory, options, ct);
```

## Invalidation

Prefer event-driven invalidation for write-heavy data:
```csharp
// After update — remove or update cache immediately
await _cache.RemoveAsync($"orders:order:{id}:v1");
```

For schema changes: increment version in key — old keys expire via TTL, no bulk delete.

## PII and sensitive data

- Never cache PII (email + phone + ID together) without encryption
- User permission caches: TTL must be ≤ token lifetime
- Never cache JWT tokens, refresh tokens, or API keys

## Serialization for IDistributedCache

Use `System.Text.Json` by default. Switch to MessagePack when:
- Cached objects > 10KB
- Cache operations appear in performance profiles
- Serialization frequency > 1000/sec

## Observability

Every caching layer must expose:
- `{service}_cache_requests_total` — counter with tags `key_prefix`, `result` (hit/miss/error)
- `{service}_cache_operation_seconds` — histogram with tag `operation` (get/set/remove)

Target hit ratio: >80% for reference data, >60% for user-specific data.

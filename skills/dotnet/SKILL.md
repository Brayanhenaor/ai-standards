---
name: dotnet
description: .NET / C# clean-code pack. Use when working in a .NET codebase (C#, ASP.NET Core, EF Core, Worker Services). Layers .NET-specific best practices — conventions, DI, error handling, EF Core, APIs, resilience, observability, caching, messaging, security, testing, Docker — on top of the universal clean-code core. Reflects current .NET standards (8 through 10; .NET 10 is the current LTS).
---

# .NET clean-code pack

This pack adds .NET-specific depth on top of `clean-code-core`. The core hierarchy still rules
(correctness > clean > anti-over-engineering); this pack tells you what "clean" looks like in
idiomatic, modern .NET. Targets .NET 8/9 and current first-party packages.

Targets modern .NET — 8 through 10, with **.NET 10 / C# 14** as the current LTS baseline. Apply the
universal core everywhere; reach into the reference below for the .NET specifics relevant to what
you're touching. Match the target framework the project actually uses — don't push a newer API onto
an older TFM. Don't impose a rule the project clearly doesn't follow — flag it (see the core's
reporting format) and apply it to new/touched code.

## Reference (load on demand)

- **`reference/conventions.md`** — naming, async/cancellation, nullable, collections, `TimeProvider`, source-generated logging.
- **`reference/di-and-config.md`** — lifetimes, captive dependencies, keyed services, the options pattern.
- **`reference/errors.md`** — `Result<T>` vs exceptions, `IExceptionHandler`, ProblemDetails (RFC 9457), exception hierarchy, logging levels.
- **`reference/data-ef.md`** — bulk ops, projections, split queries, `AsNoTracking`, connection resiliency, compiled queries, migrations.
- **`reference/api.md`** — REST semantics, status codes, versioning, pagination, ProblemDetails, OpenAPI, idempotency.
- **`reference/resilience.md`** — `Microsoft.Extensions.Http.Resilience`, timeout/retry/circuit-breaker via `IHttpClientFactory`.
- **`reference/observability.md`** — `System.Diagnostics.Metrics` + OpenTelemetry, tracing, structured logging.
- **`reference/caching.md`** — `HybridCache`, key naming, TTLs, stampede protection, PII rules.
- **`reference/messaging.md`** — naming, idempotency, outbox, schema evolution, retry/dead-letter.
- **`reference/security.md`** — JWT, authorization policies, security headers, rate limiting, injection prevention.
- **`reference/testing.md`** — xUnit, assertion libraries, NSubstitute, AAA, coverage, integration tests.
- **`reference/docker.md`** — multi-stage, chiseled images, non-root, healthchecks, compose.

## What this pack is not

It is not a company profile. Vendor- or org-specific choices (a particular metrics backend, secret
provider, orchestrator, or frozen doc templates) live in the company profile/overlay, not here. This
pack stays at the level of "best current .NET practice."

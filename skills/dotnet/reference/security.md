# Security

## Authentication (JWT)

- Secrets from configuration (User Secrets in dev, env/secret store in prod) — never hardcoded. HS256
  keys ≥ 256 bits.
- Always validate issuer, audience, lifetime, and signing key. Always set an explicit `exp`.
- Store refresh tokens hashed; support signing-key rotation via key ids.

```csharp
options.TokenValidationParameters = new()
{
    ValidateIssuer = true, ValidateAudience = true,
    ValidateLifetime = true, ValidateIssuerSigningKey = true,
    ValidIssuer = cfg["Jwt:Issuer"], ValidAudience = cfg["Jwt:Audience"],
    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(cfg["Jwt:Secret"]!))
};
```

## Authorization

Use **policies**, defined once with constants — never inline role strings in controllers.

```csharp
options.AddPolicy(Policies.AdminOnly, p => p.RequireRole("Admin"));
[Authorize(Policy = Policies.AdminOnly)]
```

## Input & data exposure

- Validate at the boundary (controllers/endpoints), not deep in services.
- Never return entities — DTOs only. Strip fields the caller isn't authorized to see before
  returning; don't rely on serialization ignores.
- Don't expose internal DB ids in public contracts; use Guids/opaque ids.

## Transport & headers

- HTTPS enforced; HSTS in prod. Add baseline security headers: `Content-Security-Policy` (where
  serving content), `X-Content-Type-Options: nosniff`, `Referrer-Policy`, frame options. Antiforgery
  for cookie-based flows.

## CORS & rate limiting

- Explicit origins/methods/headers — never `AllowAnyOrigin()` in prod.
- Rate-limit auth and public endpoints with the built-in limiter (`AddRateLimiter`, .NET 8+);
  return `429` + `Retry-After`.

## Injection & secrets

- Parameterize all SQL (`FromSqlInterpolated`/`SqlQuery<T>`) — never interpolate user input.
- Never log secrets, tokens, PII, or connection strings; never return stack traces to clients.

```csharp
// BAD
_logger.LogInformation("Login {Email} pw {Pw}", email, password);
// GOOD
_logger.LogInformation("Login attempt for {UserId}", userId);
```

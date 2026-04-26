---
paths:
  - "**/*Auth*.cs"
  - "**/*Jwt*.cs"
  - "**/*Token*.cs"
  - "**/*Authorization*.cs"
  - "**/*Permission*.cs"
  - "**/*Identity*.cs"
  - "**/*Policy*.cs"
  - "**/*Middleware*.cs"
---

# Security standards

## Authentication and JWT

- Never hardcode JWT secrets — always from `IConfiguration` (User Secrets in dev, env vars in prod)
- Set explicit expiry — never issue tokens without `exp` claim
- Validate `issuer`, `audience`, and `lifetime` in token validation parameters
- Refresh tokens must be stored hashed — never in plaintext
- Rotate signing keys without downtime using key versioning

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = config["Jwt:Issuer"],
            ValidAudience            = config["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(config["Jwt:Secret"]!))
        };
    });
```

## Authorization

- Use policies — never inline role checks in controllers
- Define policies in a single place (Host layer) using constants

```csharp
// Constants
public static class Policies
{
    public const string AdminOnly    = "AdminOnly";
    public const string OwnerOrAdmin = "OwnerOrAdmin";
}

// Registration
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(Policies.AdminOnly,
        p => p.RequireRole("Admin"));
    options.AddPolicy(Policies.OwnerOrAdmin,
        p => p.RequireAssertion(ctx => /* ... */));
});

// Usage
[Authorize(Policy = Policies.AdminOnly)]
```

## Input validation and data exposure

- Validate all input at the API boundary — controllers and endpoints only
- Never expose internal database IDs in public APIs — use GUIDs or encoded IDs
- Never return raw entity objects from API — always DTOs
- Strip fields the caller is not authorized to see before returning — don't rely on serialization ignoring

## Sensitive data

Never log or expose:
- Passwords or password hashes
- JWT tokens or refresh tokens
- API keys or secrets
- PII (emails, phone numbers, national IDs) unless explicitly required
- Connection strings or internal URLs
- Stack traces in production responses (log them, never return them)

```csharp
// BAD
_logger.LogInformation("User login: {Email} with password {Password}", email, password);

// GOOD
_logger.LogInformation("User login attempt for {UserId}", userId);
```

## HTTPS and transport

- HTTPS mandatory — redirect HTTP to HTTPS in production
- Set `Strict-Transport-Security` header (HSTS)
- Never accept plaintext passwords over HTTP

## CORS

- Configure explicit origins — never `AllowAnyOrigin()` in production
- Restrict methods and headers to what the API actually uses

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
        policy.WithOrigins(config["AllowedOrigins"]!.Split(','))
              .WithMethods("GET", "POST", "PUT", "DELETE")
              .WithHeaders("Authorization", "Content-Type"));
});
```

## Rate limiting (.NET 8+)

Apply to authentication endpoints and any public endpoint:

```csharp
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("auth", o =>
    {
        o.Window          = TimeSpan.FromMinutes(1);
        o.PermitLimit     = 10;
        o.QueueLimit      = 0;
        o.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
    });
});
```

## SQL injection prevention

- Never use raw string interpolation in EF queries
- Parameterize all raw SQL with `FromSqlInterpolated` or explicit parameters

```csharp
// BAD
var sql = $"SELECT * FROM Users WHERE Email = '{email}'";

// GOOD
var users = await _context.Users
    .FromSqlInterpolated($"SELECT * FROM Users WHERE Email = {email}")
    .ToListAsync();
```

# Security audit

Perform a dedicated security review of the current branch changes. Apply every security lens: authentication, authorization, data exposure, injection, secrets, transport, dependencies, and operational security. This is a focused security pass — use `/user:review-dotnet` for full code quality review.

**Usage:**
- `/user:security-dotnet` — audit all changes in the current branch
- `/user:security-dotnet [file or module]` — audit a specific area

---

## Step 0 — Load context

**Read `CLAUDE.md` first.** Extract:
- Auth mechanism (JWT, cookie, API key, OAuth)
- Authorization strategy (policies, roles, claims)
- Error handling strategy (what gets returned vs logged)
- External integrations and data stores

Then collect the diff:
```bash
git diff main...HEAD
git diff main...HEAD --stat
git log main...HEAD --oneline
```

Also run:
```bash
dotnet list package --vulnerable --include-transitive 2>/dev/null | grep -v "has no vulnerable"
```

---

## Step 1 — Security review dimensions

### 1. Secrets and credentials

Scan all changed files for hardcoded secrets:

- Connection strings with embedded credentials (`Password=xxx`, `pwd=xxx`)
- JWT signing keys or secrets as string literals
- API keys, tokens, or bearer values as constants or fields
- Internal service URLs containing credentials
- Base64-encoded values that decode to credentials

```csharp
// 🔴 NEVER
private const string JwtSecret = "my-super-secret-key-2024";
var conn = "Server=prod;Password=Admin123;";

// ✅ CORRECT
var secret = _config["Jwt:Secret"];
var conn = _config.GetConnectionString("Default");
```

Check appsettings.json and appsettings.*.json: secrets must NOT be present — only in User Secrets (dev) or env vars (prod).

---

### 2. Authentication

**JWT configuration:**
- `ValidateIssuer = true` — issuer must match known value
- `ValidateAudience = true` — audience must match known value
- `ValidateLifetime = true` — expired tokens must be rejected
- `ValidateIssuerSigningKey = true` — key must be validated
- `ClockSkew` set to zero or near-zero (`TimeSpan.Zero`) — default 5-min skew is exploitable
- Signing key comes from config, not hardcoded

**Token generation:**
- `exp` claim always set — never issue tokens without expiry
- `iat` and `nbf` claims present
- Minimum key length: 256-bit for HS256, 2048-bit for RS256
- Refresh tokens stored hashed (SHA-256+), never plaintext

**Session / cookie:**
- `HttpOnly = true` — prevents XSS token theft
- `Secure = true` — only over HTTPS
- `SameSite = Strict` or `Lax` — CSRF protection
- Explicit expiry

---

### 3. Authorization

- Every new endpoint has `[Authorize]` or `[AllowAnonymous]` explicit — no implicit public endpoints
- Authorization via policies, never inline role checks:
  ```csharp
  // 🔴 BAD — hardcoded role, bypassed if role name changes
  if (!User.IsInRole("Admin")) return Forbid();

  // ✅ GOOD — centralized policy
  [Authorize(Policy = Policies.AdminOnly)]
  ```
- Policies defined in Host layer, referenced by constant strings
- Resource-level authorization: does the caller own the resource they're accessing?
- IDOR: `GET /orders/{id}` — does it verify the order belongs to the authenticated user?

---

### 4. Input validation and injection

**Input validation:**
- All inputs validated at the API boundary (controller/endpoint) — never inside services
- FluentValidation validators registered for all request types
- File uploads: type validated (magic bytes, not extension), size limited, path not user-controlled

**SQL injection:**
```csharp
// 🔴 BAD
var sql = $"SELECT * FROM Users WHERE Name = '{name}'";
context.Database.ExecuteSqlRaw(sql);

// ✅ GOOD
context.Users.FromSqlInterpolated($"SELECT * FROM Users WHERE Name = {name}");
// or parameters
context.Database.ExecuteSqlRaw("SELECT * FROM Users WHERE Name = {0}", name);
```

**Command injection:**
```csharp
// 🔴 BAD — user input in shell command
Process.Start("bash", $"-c 'ls {userPath}'");

// ✅ GOOD — never pass user input to shell
```

**Path traversal:**
```csharp
// 🔴 BAD
var filePath = Path.Combine(baseDir, userInput);

// ✅ GOOD — canonicalize and verify prefix
var fullPath = Path.GetFullPath(Path.Combine(baseDir, userInput));
if (!fullPath.StartsWith(baseDir, StringComparison.OrdinalIgnoreCase))
    throw new UnauthorizedAccessException();
```

**Mass assignment:**
- Entity properties never bound directly from request — always explicit DTOs
- No `[FromBody] MyEntity entity` in controllers
- `[Bind(Include = "...")]` or explicit mapping from request DTO

---

### 5. Data exposure

- Internal database IDs not returned in API responses — use GUIDs or opaque IDs
- Error responses in production: ProblemDetails without stack trace, internal paths, or SQL
- Sensitive fields stripped from DTOs: password hashes, refresh tokens, internal flags
- Serialization: `[JsonIgnore]` on sensitive properties, or explicit allowlists
- Logging: no PII, passwords, tokens, or connection strings in log statements
  ```csharp
  // 🔴 BAD
  _logger.LogInformation("Login: {Email} pwd={Password}", email, password);

  // ✅ GOOD
  _logger.LogInformation("Login attempt for user {UserId}", userId);
  ```

---

### 6. Transport security

- HTTPS enforced: `app.UseHttpsRedirection()` present
- HSTS configured: `app.UseHsts()` with appropriate `MaxAge`
- Certificates not hardcoded or committed
- External HTTP calls: `HttpClient` uses HTTPS URLs, no `ServerCertificateCustomValidationCallback` that ignores errors

---

### 7. CORS

- No `AllowAnyOrigin()` in production code paths
- Allowed origins from configuration, not hardcoded
- Methods and headers restricted to what the API actually needs
- `AllowCredentials()` only when paired with explicit origins (not wildcard)

---

### 8. Rate limiting

- Authentication endpoints (`/login`, `/register`, `/forgot-password`, `/token`) have rate limiting
- Password reset and MFA endpoints especially
- Rate limit by IP and/or user, not just globally
- `429 Too Many Requests` returned with `Retry-After` header

---

### 9. Security headers

New middleware or endpoint pipelines must include:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` (or `SAMEORIGIN`)
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy` (for endpoints serving HTML)

Check: is `app.UseXxx()` ordering correct? Authentication before Authorization.

---

### 10. Dependency vulnerabilities

Run and review:
```bash
dotnet list package --vulnerable --include-transitive
```

- Any **Critical** or **High** CVE in production packages → 🔴 blocker
- **Medium** CVEs → 🟡 fix before next sprint
- Flag if packages are significantly out of date (major version behind)

---

### 11. OWASP Top 10 mapping

For each changed area, flag applicable OWASP risks:

| OWASP | Applicable to |
|-------|---------------|
| A01 — Broken Access Control | Authorization, IDOR, resource ownership checks |
| A02 — Cryptographic Failures | Secrets, token storage, HTTPS, key length |
| A03 — Injection | SQL, command, path traversal, LDAP |
| A04 — Insecure Design | Missing rate limiting, missing auth on sensitive ops |
| A05 — Security Misconfiguration | CORS wildcard, debug endpoints in prod, HSTS missing |
| A06 — Vulnerable Components | Outdated NuGet packages with CVEs |
| A07 — Auth Failures | JWT misconfiguration, session fixation, brute force |
| A08 — Software Integrity | NuGet feeds, build pipeline integrity |
| A09 — Logging Failures | PII in logs, missing audit trail for sensitive ops |
| A10 — SSRF | User-controlled URLs in `HttpClient` calls |

---

## Step 2 — Output format

```
## Auditoría de seguridad — [branch o feature]

### 🔴 Crítico
Vulnerabilidades explotables o incumplimientos de compliance. Bloquean el merge.

- **[archivo:línea]** `[OWASP A0X]` — descripción del problema
  - *Impacto:* qué puede hacer un atacante
  - *Fix:* solución exacta con código si aplica

### 🟡 Alto
Riesgo real pero requiere condiciones específicas o acceso previo.

- **[archivo:línea]** `[OWASP A0X]` — descripción
  - *Fix:* corrección concreta

### 🔵 Medio / Hardening
Mejoras de postura de seguridad — no vulnerabilidades activas pero sí superficie de ataque.

- **[archivo:línea]** — descripción y recomendación

### ℹ️ Dependencias vulnerables
- [lista de paquetes con CVE, o "ninguna detectada"]

### ✅ Áreas verificadas sin hallazgos
- [lista de dimensiones revisadas y limpias]
```

Cerrar con:
- 🔴 **No hacer merge** — vulnerabilidades críticas o altas sin resolver
- 🟡 **Merge con plan de remediación** — riesgo medio, documentar en backlog
- ✅ **Sin hallazgos de seguridad** — postura aceptable para producción

---

## Output rules

- Every finding references exact file and line — never generic "the auth code has an issue"
- Every 🔴 finding includes the concrete attack scenario and exact fix
- Map every finding to OWASP category
- Dependency findings include CVE ID and affected version
- If security-dotnet is run after review-dotnet, skip dimensions already covered — focus on depth, not repetition
- When `CLAUDE.md` says the project has no auth layer, skip auth sections but flag it as an architectural risk if any endpoint exists

# Configure Infisical secrets provider

Wire up `BTW.SecretsProvider` (internal NuGet) to load secrets from Infisical and/or a local JSON file into the .NET configuration system.

**Usage:**
- `/user:infisical-dotnet` — configure Infisical in the current project
- `/user:infisical-dotnet review` — review existing Infisical setup for issues

## $ARGUMENTS

---

## Step 1 — Read the project before touching anything

- Read `CLAUDE.md` for project-specific notes
- Check the `.csproj` to detect target framework (.NET 6/7 vs 8+)
- Read `Program.cs` to understand current builder type (`WebApplication.CreateBuilder` / `Host.CreateApplicationBuilder`)
- Check `appsettings.json` for existing `Infisical` section

---

## Step 2 — Install the package

```bash
dotnet add package BTW.SecretsProvider
```

---

## Step 3 — Configure appsettings.json

Add the `Infisical` section. **`ClientSecret` must NOT be committed here** — leave it as placeholder and explain where the real value must come from (Docker secret or env var).

```json
{
  "Infisical": {
    "ProjectId": "REPLACE_WITH_PROJECT_ID",
    "ClientId": "REPLACE_WITH_CLIENT_ID",
    "ClientSecret": "",
    "Host": "https://app.infisical.com"
  }
}
```

- `ProjectId` and `ClientId` are non-sensitive — safe to commit
- `ClientSecret` must come from Docker secrets (`/app/secrets.json`) or environment variable — never hardcode
- `Env` is optional — omit to use automatic resolution (see Step 5)

---

## Step 4 — Wire up in Program.cs

### .NET 8+ (IHostApplicationBuilder)

```csharp
using BTW.SecretsProvider;

var builder = WebApplication.CreateBuilder(args);

// Load ClientSecret from /app/secrets.json (Docker secret mount)
builder.AddJsonSecrets();

// Load all secrets from Infisical
builder.AddInfisicalSecrets();
```

### .NET 6/7 — HostApplicationBuilder

```csharp
using BTW.SecretsProvider;

var builder = Host.CreateApplicationBuilder(args);

builder.AddJsonSecrets();
builder.AddInfisicalSecrets();
```

### .NET 6/7 — WebApplicationBuilder (ConfigurationManager)

```csharp
using BTW.SecretsProvider;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonSecrets();
builder.Configuration.AddInfisicalSecrets(
    environmentName: builder.Environment.EnvironmentName
);
```

**Order matters:** `AddJsonSecrets()` must come before `AddInfisicalSecrets()` so the ClientSecret loaded from the JSON file is available when Infisical initializes.

---

## Step 5 — Environment resolution (automatic)

The provider resolves the Infisical environment in this priority order:

| Priority | Source | Example |
|---|---|---|
| 1 | `env` parameter | `builder.AddInfisicalSecrets(env: "dev")` |
| 2 | `Infisical:Env` in appsettings.json | `"Env": "qa"` |
| 3 | App environment → Production | → `"prod"` |
| 3 | App environment → anything else | → `"qa"` (or `"staging"` if `useStagingName: true`) |

For most projects: do not set `Infisical:Env` — let the app environment drive it automatically.

---

## Step 6 — Secret path organization

Infisical supports hierarchical paths. Use `secretPath` to load from a sub-path in addition to root `/`:

```csharp
// Loads "/" + "/api" secrets
builder.AddInfisicalSecrets(secretPath: "/api");

// Loads "/" + "/workers/email"
builder.AddInfisicalSecrets(secretPath: "/workers/email");
```

Group secrets by service concern, not by environment (environments are handled by Infisical natively).

---

## Step 7 — Key naming convention in Infisical

Infisical key names use `__` (double underscore) as the hierarchy separator — automatically converted to `:` in .NET IConfiguration:

| Infisical key | .NET IConfiguration key |
|---|---|
| `DATABASE__HOST` | `DATABASE:HOST` |
| `ConnectionStrings__DefaultConnection` | `ConnectionStrings:DefaultConnection` |
| `RabbitMq__HostName` | `RabbitMq:HostName` |

This maps directly to the standard .NET nested config convention (`RabbitMq__HostName` = environment variable style).

---

## Step 8 — Reading secrets in services

Secrets are available via standard `IConfiguration` — no Infisical-specific code in services:

```csharp
// Via IConfiguration
public class MyService(IConfiguration config)
{
    void Connect() => config["ConnectionStrings:DefaultConnection"];
}

// Via IOptions<T> (preferred — follows DIP)
builder.Services.Configure<DatabaseOptions>(
    builder.Configuration.GetSection("Database"));

public class MyService(IOptions<DatabaseOptions> options) { }
```

Never inject `IConfiguration` outside `Program.cs` / `Host/` layer — bind to typed options.

---

## Step 9 — Docker Compose / Swarm: inject ClientSecret

**Local dev** — `.env` file (never committed):
```
Infisical__ClientSecret=your-client-secret-here
```

**Swarm (recommended)** — Docker secret mounted as file:

```yaml
# docker-compose.yml
services:
  myapi:
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
    secrets:
      - infisical_client_secret

secrets:
  infisical_client_secret:
    external: true
```

Mount the secret as `/app/secrets.json` so `AddJsonSecrets()` picks it up:

```json
{
  "Infisical": {
    "ClientSecret": "the-actual-secret"
  }
}
```

Or pass it directly as environment variable (the provider reads it via IConfiguration):
```yaml
environment:
  - Infisical__ClientSecret=/run/secrets/infisical_secret
```

---

## Step 10 — Verify setup

After wiring up, confirm:
- [ ] `BTW.SecretsProvider` package added to `.csproj`
- [ ] `AddJsonSecrets()` called before `AddInfisicalSecrets()`
- [ ] `ClientSecret` is NOT in committed `appsettings.json`
- [ ] `.env` or Docker secret provides `ClientSecret` at runtime
- [ ] At least one service reads a secret via `IOptions<T>`, not raw `IConfiguration`
- [ ] `appsettings.json` has `ProjectId`, `ClientId`, `Host` filled in

---

## Error messages reference

| Message | Cause | Fix |
|---|---|---|
| `Configuración de Infisical incompleta` | Missing `ProjectId`, `ClientId`, `ClientSecret`, or `Host` | Verify all four fields are set at runtime |
| `No se pudo conectar con Infisical` | Network error or wrong `Host` | Check `Host` URL and that Infisical is reachable from the container |

The provider never throws — on failure it logs to console and continues with local config only.

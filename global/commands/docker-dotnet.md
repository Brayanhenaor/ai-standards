# Docker setup review and guidance

Review or generate Docker configuration for the current .NET project.

**Usage:**
- `/user:docker-dotnet` — review existing Dockerfile and docker-compose.yml
- `/user:docker-dotnet generate` — generate Dockerfile and docker-compose.yml from scratch

---

## Dockerfile standards

- Multi-stage build: separate build stage from runtime
- Runtime base image: `mcr.microsoft.com/dotnet/aspnet` — never the SDK image
- Never run as root — define an unprivileged user
- Always include `.dockerignore`; never copy `bin/`, `obj/`, `.git/`, `*.user`, `appsettings*.json` (use env vars instead)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

---

## Docker Compose standards

Every service must have:

### Healthcheck (mandatory)
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Restart policy
```yaml
restart: unless-stopped   # long-lived services (API, workers)
restart: on-failure       # one-shot jobs
```

### Dependencies with health condition — never just by name
```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_healthy
```

### Additional rules
- Secrets and env vars from `.env` — never hardcoded in the compose file
- Commit `.env.example` with all variables and example values; never commit `.env`
- Set `mem_limit` and `cpus` on services that could consume unbounded resources
- Use named volumes for persistent data — never relative paths in production
- Expose only the ports strictly needed on the host

---

## Health checks in the API

Register in `Host/` via `AddHealthChecks()`:

```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>()        // readiness
    .AddRedis(connectionString);              // readiness

app.MapHealthChecks("/health");               // liveness
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

- `/health` — liveness: process is alive
- `/health/ready` — readiness: dependencies (DB, cache, external services) are available

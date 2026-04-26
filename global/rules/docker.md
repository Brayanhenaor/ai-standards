---
paths:
  - "**/Dockerfile"
  - "**/*.dockerfile"
  - "**/docker-compose*.yml"
  - "**/.dockerignore"
---

# Docker standards

## Dockerfile

- Multi-stage build: separate build stage from runtime
- Runtime base image: `mcr.microsoft.com/dotnet/aspnet` — never the SDK image in production
- Never run as root — define an unprivileged user explicitly
- Always include `.dockerignore`; exclude `bin/`, `obj/`, `.git/`, `*.user`, `appsettings*.json`

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

## Docker Compose

Every service must have all three of the following:

### 1. Healthcheck
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 2. Restart policy
```yaml
restart: unless-stopped   # long-lived services (API, workers)
restart: on-failure       # one-shot jobs or batch processors
```

### 3. Dependencies with health condition
Never use bare `depends_on` — always require health:
```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_healthy
```

## Additional rules

- Secrets and env vars from `.env` — never hardcoded in compose file
- Commit `.env.example` with all variables and example values; never commit `.env`
- Set `mem_limit` and `cpus` on services that could consume unbounded resources
- Use named volumes for persistent data — never relative host paths in production
- Expose only ports strictly needed on the host

## Health checks in the API

Register in `Host/` with `AddHealthChecks()`:

```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>(tags: new[] { "ready" })
    .AddRedis(connectionString, tags: new[] { "ready" });

app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});
```

- `/health` — liveness: process is alive
- `/health/ready` — readiness: DB, cache, and external dependencies are available

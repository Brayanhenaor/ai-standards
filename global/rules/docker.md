---
paths:
  - "**/Dockerfile"
  - "**/*.dockerfile"
  - "**/docker-compose*.yml"
  - "**/.dockerignore"
  - "**/deploy.sh"
  - "**/deploy.ps1"
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

## Multi-environment compose structure (Swarm)

Use layered composition — one base file, one override per environment:

```
docker-compose.yml           # base: images, networks (overlay), deploy config, healthchecks
docker-compose.override.yml  # local dev: bridge network, host ports, local build context
docker-compose.uat.yml       # UAT overrides only: env vars, ports, replicas
docker-compose.prd.yml       # PRD overrides only: replicas, resource limits
```

**Rules:**
- Base file must be Swarm-compatible (use `deploy:` block, `overlay` network)
- `docker-compose.override.yml` is auto-loaded by `docker compose up` — use for local dev only
- Never define replicas in base — define in `uat.yml` / `prd.yml`
- Network names include environment suffix: `projectname-network-uat`, `projectname-network-prd`
- Stack name pattern: `{project}-{env}` (e.g. `integrationar-uat`)

**Swarm deploy block (base):**
```yaml
deploy:
  replicas: 1
  restart_policy:
    condition: any
    delay: 5s
    window: 120s
  update_config:
    parallelism: 1
    delay: 10s
    failure_action: rollback
    order: start-first
  rollback_config:
    parallelism: 1
    delay: 5s
    order: start-first
  resources:
    limits:
      memory: 512M
      cpus: '1'
    reservations:
      memory: 256M   # 50% of limit
      cpus: '0.25'
```

- `order: start-first` for stateless services (zero-downtime)
- `order: stop-first` for Prometheus, stateful services
- Memory reservation = 50% of limit
- `restart_policy.condition: any` in base; never override to `none`

**Deploy script pattern:**
```bash
#!/usr/bin/env bash
set -e
ENV="${1:?Usage: $0 <uat|prd>}"
STACK_NAME="{project}-$ENV"
docker stack deploy \
  --compose-file docker-compose.yml \
  --compose-file "docker-compose.$ENV.yml" \
  --with-registry-auth --prune "$STACK_NAME"
```

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

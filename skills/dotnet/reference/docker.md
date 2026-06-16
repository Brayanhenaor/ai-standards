# Docker

## Dockerfile

- Multi-stage: SDK image builds, runtime image runs. Never ship the SDK image.
- Prefer **chiseled** runtime images — minimal, rootless, smaller attack surface.
- Modern .NET images already run as a non-root user (`$APP_UID`) and listen on port 8080 — don't
  re-add root. Always ship a `.dockerignore` (exclude `bin/`, `obj/`, `.git/`, `*.user`,
  `appsettings.*.json`).

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS final
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

## Health checks

```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>(tags: ["ready"]);
app.MapHealthChecks("/health");                                  // liveness
app.MapHealthChecks("/health/ready", new() { Predicate = c => c.Tags.Contains("ready") });
```

## Compose

Every service: a healthcheck, a restart policy (`unless-stopped` for long-lived), and
health-conditioned dependencies — never bare `depends_on`.

```yaml
depends_on:
  db: { condition: service_healthy }
```

- Secrets/env from `.env` (commit `.env.example`, never `.env`).
- Set memory/cpu limits on anything that can grow unbounded; named volumes for persistent data;
  expose only the ports you need.
- For multi-environment, layer compose files (base + per-env overrides). Orchestrator-specific
  details (Swarm/Kubernetes deploy blocks) belong in the company profile, not in this baseline.

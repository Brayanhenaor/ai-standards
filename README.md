# ai-standards — .NET

Claude Code standards for .NET development teams.

---

## Setup (una vez por máquina)

```bash
npx github:Brayanhenaor/ai-standards
```

Instala los estándares globales y los comandos en `~/.claude/`.

---

## Por cada proyecto nuevo

Abre el proyecto en Claude Code y ejecuta:

```
/user:init-dotnet
```

Claude analiza el proyecto y genera el `CLAUDE.md` adaptado a su arquitectura real.

---

## Comandos instalados

### Discover & Plan
| Comando | Descripción |
|---|---|
| `/user:init-dotnet` | Analiza el proyecto y genera el `CLAUDE.md` adaptado (ejecutar una vez) |
| `/user:plan-dotnet` | 3 opciones arquitectónicas con análisis de trade-offs antes de implementar |
| `/user:adr-dotnet` | Genera Architecture Decision Record de la opción elegida |

### Expert lenses (análisis profundo bajo demanda)
| Comando | Descripción |
|---|---|
| `/user:architect-dotnet` | Revisión de arquitecto senior: escalabilidad, HA, fault tolerance, sistemas distribuidos |
| `/user:concurrency-dotnet` | Experto en concurrencia: race conditions, deadlocks, async correctness, DI lifetimes |
| `/user:performance-dotnet` | Ingeniero de performance: GC, allocations, N+1, EF queries, I/O efficiency |
| `/user:domain-dotnet` | Experto DDD: aggregate boundaries, invariants, value objects, ubiquitous language |

### Build
| Comando | Descripción |
|---|---|
| `/user:scaffold-dotnet` | Genera scaffold completo de feature (todas las capas + unit tests) |
| `/user:debug-dotnet` | Debugging estructurado: collect → hypothesize → one change → verify |

### Validate & Ship
| Comando | Descripción |
|---|---|
| `/user:review-dotnet` | Revisión completa del branch antes de PR (10+ dimensiones) |
| `/user:test-dotnet` | Genera unit tests de cambios pendientes o un commit específico |
| `/user:commit-dotnet` | Genera mensaje de commit en Conventional Commits |
| `/user:changelog-dotnet` | Genera documento de control de cambios profesional |

### Infrastructure & Observability
| Comando | Descripción |
|---|---|
| `/user:docker-dotnet` | Revisa o genera Dockerfile multi-stage y docker-compose |
| `/user:grafana-dotnet` | Genera dashboard JSON de Grafana desde métricas Prometheus del proyecto |
| `/user:infisical-dotnet` | Configura provider de secretos con Infisical |

### Documentation
| Comando | Descripción |
|---|---|
| `/user:manual-dotnet` | Extrae información técnica completa para manual profesional (JSON) |
| `/user:standup` | Genera resumen del trabajo del día desde commits |

---

## Estructura del repo

```
global/
  CLAUDE.md              ← reglas globales de empresa  (~/.claude/CLAUDE.md)
  settings.json          ← configuración de hooks       (~/.claude/settings.json)
  commands/              ←                              ~/.claude/commands/
    init-dotnet.md
    plan-dotnet.md
    adr-dotnet.md
    architect-dotnet.md
    concurrency-dotnet.md
    performance-dotnet.md
    domain-dotnet.md
    scaffold-dotnet.md
    debug-dotnet.md
    review-dotnet.md
    test-dotnet.md
    commit-dotnet.md
    changelog-dotnet.md
    docker-dotnet.md
    grafana-dotnet.md
    infisical-dotnet.md
    manual-dotnet.md
    standup.md
  rules/                 ← reglas detalladas por área   ~/.claude/rules/
    csharp-conventions.md
    di-lifetimes.md
    docker.md
    resilience.md
    security.md
    testing.md
    ef-advanced.md
    observability.md
  hooks/                 ←                              ~/.claude/hooks/
    cs-dirty-flag.sh
    build-check.sh
    test-runner.sh
    migration-guard.sh
    README.md

templates/
  dotnet/
    CLAUDE.md            ← base para proyectos .NET (init-dotnet lo adapta)

bin/
  cli.js                 ← entry point del npx

package.json
```

El proyecto solo tiene `CLAUDE.md`. Todo lo demás es global e invisible al dev.

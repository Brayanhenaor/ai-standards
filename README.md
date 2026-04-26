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

| Comando | Descripción |
|---|---|
| `/user:init-dotnet` | Analiza el proyecto y genera el `CLAUDE.md` adaptado (ejecutar una vez por proyecto) |
| `/user:plan-dotnet` | Planea un requerimiento con trade-offs antes de implementar |
| `/user:review-dotnet` | Revisión completa de todos los cambios del branch antes de PR |
| `/user:commit-dotnet` | Genera mensaje de commit en Conventional Commits |
| `/user:test-dotnet` | Genera unit tests de cambios pendientes o de un commit específico |
| `/user:standup` | Genera resumen del trabajo del día |

---

## Estructura del repo

```
global/
  CLAUDE.md              ← reglas globales de empresa (~/.claude/CLAUDE.md)
  commands/
    init-dotnet.md
    plan-dotnet.md
    review-dotnet.md
    commit-dotnet.md
    test-dotnet.md
    standup.md

templates/
  dotnet/
    CLAUDE.md            ← base para proyectos .NET (init-dotnet lo adapta)

bin/
  cli.js                 ← entry point del npx

package.json
```

# ai-standards

Claude Code standards for development teams.

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
/user:init-btw
```

Claude analiza el proyecto y genera el `CLAUDE.md` adaptado a su arquitectura real.

---

## Comandos instalados

| Comando | Descripción |
|---|---|
| `/user:init-btw` | Analiza el proyecto y genera el `CLAUDE.md` adaptado (ejecutar una vez por proyecto) |
| `/user:plan-implementation` | Planea un requerimiento con trade-offs antes de implementar |
| `/user:review` | Revisión completa de todos los cambios del branch antes de PR |
| `/user:commit-message` | Genera mensaje de commit en Conventional Commits |
| `/user:standup` | Genera resumen del trabajo del día |

---

## Estructura del repo

```
global/
  CLAUDE.md              ← reglas globales de empresa (~/.claude/CLAUDE.md)
  commands/
    init-btw.md          ← /user:init-btw
    plan-implementation.md
    review.md
    commit-message.md
    standup.md

templates/
  dotnet/
    CLAUDE.md            ← base para proyectos .NET (init-btw lo adapta)

bin/
  cli.js                 ← entry point del npx

package.json
```

---

## Agregar soporte para otra tecnología

1. Crea `templates/[tech]/CLAUDE.md` con las convenciones del stack
2. Actualiza `global/commands/init-btw.md` para detectar y usar ese template

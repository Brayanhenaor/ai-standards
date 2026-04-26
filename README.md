# ai-standards

Estándares de Claude Code para el equipo de desarrollo.

---

## Setup en un proyecto (1 comando)

Desde la **raíz del proyecto**:

**Mac / Linux:**
```bash
curl -fsSL "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.sh?t=$(date +%s)" | bash
```

**Windows (PowerShell):**
```powershell
iwr "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.ps1?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" | iex
```

Luego abre el proyecto en Claude Code y ejecuta:
```
/project:init-btw
```

Claude analizará el proyecto y completará la configuración automáticamente.

---

## ¿Qué instala?

| Archivo | Descripción |
|---|---|
| `CLAUDE.md` | Reglas y estándares del proyecto |
| `.claude/settings.json` | Permisos pre-configurados |
| `.claude/commands/init-btw.md` | `/project:init-btw` — configuración inicial |
| `.claude/commands/review.md` | `/project:review` — revisión completa antes de PR |
| `.claude/commands/commit-message.md` | `/project:commit-message` — conventional commits |
| `.claude/commands/pr.md` | `/project:pr` — descripción de PR |
| `.claude/commands/plan-implementation.md` | `/project:plan-implementation` — planificación |
| `.claude/commands/task.md` | `/project:task` — desglose técnico |
| `.claude/commands/fix.md` | `/project:fix` — debugging sistemático |

---

## Setup global (opcional)

Instala reglas globales y el comando `/user:standup` en `~/.claude/`:

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.sh | bash
```

**Windows:**
```powershell
iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.ps1 | iex
```

---

## Estructura del repo

```
templates/dotnet/          ← plantilla para proyectos .NET
  CLAUDE.md                ← reglas del proyecto
  .claude/
    settings.json
    commands/              ← 7 comandos /project:*

global/                    ← se instala en ~/.claude/
  CLAUDE.md                ← reglas globales de empresa
  commands/
    standup.md             ← /user:standup

scripts/
  setup-project.sh         ← instalador de proyecto (Mac/Linux)
  setup-project.ps1        ← instalador de proyecto (Windows)
  setup.sh                 ← instalador global (Mac/Linux)
  setup.ps1                ← instalador global (Windows)
```

---

## Agregar soporte para otra tecnología

1. Crea `templates/[tech]/CLAUDE.md` con las convenciones del stack
2. Crea `templates/[tech]/.claude/commands/` con los 7 comandos estándar
3. El script detecta la tech por archivos característicos (`*.csproj` → dotnet, `angular.json` → angular)

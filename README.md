# ai-standards

Estándares de Claude Code para el equipo de desarrollo de [Empresa].

## Setup en un proyecto (1 comando)

Desde la **raíz del proyecto**, ejecutar:

**Windows (PowerShell):**
```powershell
iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.ps1 | iex
```

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.sh | bash
```

El script detecta la tecnología automáticamente y genera:
- `CLAUDE.md` personalizado con los datos reales del proyecto
- `.claude/commands/` con los 6 comandos estándar
- `.claude/settings.json` con permisos preconfigurados

Los placeholders que no se puedan detectar quedan marcados como `[COMPLETAR]`. Al abrir el proyecto en Claude Code, Claude los completa analizando el código.

| Repo contiene | Plantilla aplicada |
|---|---|
| `*.csproj` / `*.sln` | .NET (Clean Architecture, EF Core, Mapster) |

---

## Setup global (opcional)

Instala comandos globales disponibles en **todos los proyectos** de la máquina:

**Windows (PowerShell):**
```powershell
iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.ps1 | iex
```

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.sh | bash
```

Instala en `~/.claude/`:
- `CLAUDE.md` — reglas globales de la empresa
- `commands/standup.md` — `/user:standup`

## Estructura

```
global/                              # Se instala en ~/.claude/
  CLAUDE.md                          # Reglas globales de la empresa
  commands/
    init-repo.md                     # /user:init-repo (detecta tech automáticamente)
    standup.md                       # /user:standup

templates/
  dotnet/                            # Repos .NET / ASP.NET Core
    CLAUDE.md
    .claude/
      settings.json
      commands/
        review.md                    # /project:review
        pr.md                        # /project:pr
        task.md                      # /project:task
        fix.md                       # /project:fix


scripts/
  setup.ps1                          # Instalador Windows
  setup.sh                           # Instalador Mac/Linux
```

## Agregar una tecnología nueva

1. Crea `templates/[tech]/CLAUDE.md` con las convenciones del stack
2. Crea `templates/[tech]/.claude/commands/` con los 4 comandos estándar
3. Agrega la detección en `global/commands/init-repo.md` (tabla del Paso 1)

## Actualizar estándares

Edita los archivos en este repo y haz commit a main.
Cada dev re-ejecuta el script de instalación para obtener la versión actualizada.

# Inicializar estándares de Claude Code en este repo

Analiza este repositorio, detecta la tecnología y crea su CLAUDE.md personalizado.

## Paso 1 — Detectar tecnología

Busca estos archivos para identificar el stack:

| Archivo presente | Tecnología |
|---|---|
| `*.csproj` o `*.sln` | .NET |
| Ninguno conocido | Preguntar al usuario antes de continuar |

## Paso 2 — Analizar el repo según la tecnología

**Si es .NET:**
- Lee los `.csproj` para ver PackageReference (MediatR, EF Core, FluentValidation, etc.)
- Revisa la estructura de carpetas para detectar la arquitectura (Clean Architecture, capas, etc.)
- Identifica el tipo de proyecto: Web API, Worker Service, Blazor
- Detecta el proveedor de base de datos en EF Core (SqlServer, Npgsql, Sqlite)
- Revisa Program.cs para entender el setup

## Paso 3 — Crear archivos

Descarga la plantilla:
- .NET: `https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/templates/dotnet/CLAUDE.md`

Personaliza la plantilla reemplazando todos los placeholders con lo detectado en el paso 2.
Si algo no puedes detectarlo con certeza, deja `[COMPLETAR: descripción de qué falta]`.

Crea `.claude/commands/` descargando los 4 comandos desde `templates/dotnet/.claude/commands/`.

Crea `.claude/settings.json` descargando el de `templates/dotnet/.claude/settings.json`.

## Paso 4 — Resumen

Muestra al finalizar:
- Tecnología detectada y cómo la detectaste
- Qué archivos creaste
- Qué placeholders quedaron con [COMPLETAR] y por qué
- Comandos disponibles con `/project:*`

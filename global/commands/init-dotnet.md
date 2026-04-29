# Initialize and adapt standards to the project

Run this analysis ONCE. The goal is to generate a CLAUDE.md that reflects both the company base standards and the reality of this specific project.

---

## Phase 1 — Analyze the solution

Explore the project thoroughly before writing anything.

### General structure
- Read the `.sln` and all `.csproj` files to understand projects and their dependencies
- Map the full folder structure (ignore bin/, obj/, .git/, .vs/, node_modules/)
- Identify how many projects exist and the role of each

### Stack and dependencies
- Extract all `PackageReference` entries from each `.csproj`
- Identify key libraries: ORM, messaging, logging, auth, mapping, etc.
- Detect the .NET and C# version of each project

### Real architecture
- Read `Program.cs` / `Startup.cs` to understand DI setup and middlewares
- Analyze namespaces to understand the real project layers
- Read 2–3 representative files per layer (controllers, services, repositories, entities)
- Detect patterns in use: CQRS? Repository pattern? Clean Architecture? Simple layers?
- Identify if there is an `ApiResponse<T>` or similar base response class
- Detect error handling approach: global middleware? try/catch per controller?

### Real code conventions
- Analyze actual naming of files and classes (Request/Response? Dto? ViewModel?)
- Detect how async methods are named (do they have the `Async` suffix?)
- Identify whether they use `var` or explicit types
- Detect injection style: constructor? `inject()`?
- Check if constants are organized in static classes or scattered as string literals

### Technical debt and deviations
- Identify parts of the project that do NOT follow the ideal architecture
- Detect common anti-patterns: business logic in controllers, exposed DbContext, etc.
- Note what is well implemented and what needs eventual refactoring

---

## Phase 2 — Download the base template and adapt it

**Download the full template first — never generate CLAUDE.md from scratch.**

```bash
curl -fsSL "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/templates/dotnet/CLAUDE.md" -o CLAUDE.md
```

The project will only have this file. Detailed rules (`docker.md`, `resilience.md`, `ef-advanced.md`, `testing.md`, `security.md`) are already installed globally in `~/.claude/rules/` by the `npx` setup — they are not needed in the project.

Then read the downloaded file and apply the following adaptations:

### Sections you MUST modify
- **Title** (`# [ProjectName]`) → real project name
- **Stack** → real versions and packages detected in the `.csproj` files
- **Architecture** → describe WHAT IS THERE: real layers, real folders, real patterns
- **C# conventions** → adjust only what the project already does differently (naming, var vs explicit type, etc.)

### Sections you must NOT touch
Everything else stays exactly as in the template:
- Error handling, logging, security, performance, resilience
- EF Core, Mapster, DTOs, testing, code quality
- Documentation, what NOT to do

### Balance: base rules vs adaptation

| Section | What to do |
|---|---|
| Quality, security, performance | Keep unchanged — non-negotiable |
| Ideal architecture | Adapt: describe the real architecture + indicate evolution direction |
| Naming and conventions | Adapt to the project's real style to avoid inconsistencies |
| Patterns (CQRS, Repository, etc.) | Include only those already in use or with clear adoption intent |
| Detected technical debt | Add `## Current project state` section with real findings |

### Mandatory additional section if there is debt

If you detect significant deviations from standards, add this section to CLAUDE.md:

```markdown
## Current project state

### What is working well
- [list of good practices already in place]

### Technical debt detected
- [CRITICAL] description — affects correctness or security
- [IMPROVEMENT] description — standards violation, medium priority
- [TECHNICAL] minor debt — for a future refactor sprint

### Evolution direction
- [recommended gradual refactors and suggested order]
```

---

## Phase 3 — Write CLAUDE.md and generate PROJECT_STATUS.md

### 3a — Write CLAUDE.md
1. Write the adapted CLAUDE.md over the downloaded file
2. If there is significant technical debt, add the `## Current project state` section before `## Available commands`

### 3b — Generate docs/PROJECT_STATUS.md

Create `docs/PROJECT_STATUS.md` as a living snapshot of the project's health. This file is for the team — not for Claude rules. Use the findings from Phase 1.

```markdown
# Estado del proyecto — [NombreProyecto]

> Fecha de análisis: [fecha actual]
> Analizado por: `/user:init-dotnet`

## Descripción general
[Qué hace el proyecto, su propósito y tipo de sistema — inferido del código]

## Arquitectura
[Descripción de la arquitectura real encontrada: capas, patrones, dirección de dependencias]

## Stack
| Componente | Versión / Paquete |
|---|---|
| .NET | X.X |
| [Paquete clave] | X.X.X |
| ... | ... |

## Deuda técnica

### 🔴 Crítico
Elementos que afectan seguridad, correctitud o generan bugs silenciosos.
- [descripción] — [archivos o áreas afectadas]

### 🟡 Mejoras
Violaciones de estándares o problemas de diseño a resolver en próximos sprints.
- [descripción] — [archivos o áreas afectadas]

### 🔵 Técnico
Cleanup menor, naming o problemas estructurales.
- [descripción]

## Observaciones de seguridad
[Gaps de auth, secrets hardcodeados, falta de validación de input, IDs expuestos, etc. — o "Ninguno detectado"]

## Observaciones de performance
[Riesgos de N+1, paginación faltante, queries sin límite, problemas de sockets, etc. — o "Ninguno detectado"]

## Cobertura de tests
[Qué está testeado, qué falta, si los caminos críticos están cubiertos]

## Documentación faltante
[Secciones del README ausentes, ADRs que deberían existir, configuración sin documentar, etc. — o "Ninguno detectado"]

## Roadmap de evolución recomendado
Ordenado por prioridad:
1. [Primera cosa a resolver — por qué]
2. [Segunda cosa — por qué]
3. ...
```

Si una sección no tiene nada que reportar, escribir `Ninguno detectado` en lugar de omitir la sección — esto confirma que el área fue revisada.

---

## Phase 4 — Confirm

Present the following summary to the dev:

```
✅ Project initialized: [ProjectName]

Stack detected:
  • .NET X / C# X
  • [project type]
  • [DB and ORM]
  • [key packages]

Architecture detected:
  • [1–2 line description of what you found]

Files generated:
  • CLAUDE.md              — rules adapted to this project
  • docs/PROJECT_STATUS.md — project health snapshot

[If debt exists]: ⚠️ N technical debt items detected — see docs/PROJECT_STATUS.md

Available commands:

  Planificación y diseño:
  /user:plan-dotnet        — 3 opciones arquitectónicas con análisis de riesgos
  /user:adr-dotnet         — genera ADR a partir de la opción elegida en plan-dotnet

  Análisis experto (activados automáticamente al codificar, o invocables explícitamente):
  /user:architect-dotnet   — arquitecto senior: escalabilidad, HA, tolerancia a fallos
  /user:concurrency-dotnet — experto concurrencia: race conditions, deadlocks, async
  /user:performance-dotnet — ingeniero de performance: GC, allocations, N+1, caching
  /user:domain-dotnet      — experto DDD: aggregates, value objects, invariantes

  Generación de código:
  /user:scaffold-dotnet    — genera scaffold completo de un feature (todas las capas + tests)

  Calidad y entrega:
  /user:review-dotnet      — revisión completa del branch antes del PR
  /user:test-dotnet        — genera unit tests para cambios pendientes o un commit
  /user:commit-dotnet      — genera mensaje de commit en Conventional Commits
  /user:changelog-dotnet   — genera documento de control de cambios

  Setup e infraestructura:
  /user:init-dotnet        — este comando (ya ejecutado)
  /user:docker-dotnet      — revisa o genera configuración Docker/Compose
```

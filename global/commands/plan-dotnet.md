# Plan implementation — architectural consultant

Receive a requirement and act as an architectural consultant: inform, surface risks, and propose options before any code is written. The developer decides — Claude informs.

## Requirement
$ARGUMENTS

---

## Phase 1 — Understand before planning

Before proposing anything, analyze the requirement and explicitly state:

- The **real technical problem** (root cause, not the symptom)
- **Constraints** — technical and business — that condition the solution
- **System components** involved (services, databases, queues, external integrations)
- **Expected load scenarios** (volume, concurrency, frequency)
- **Data consistency level** required (eventual, strong, transactional)
- **Non-functional constraints** (latency, availability, fault tolerance, idempotency)
- Whether this is **greenfield or modifying existing code**

**Rule for asking questions:**
Only ask when **both** conditions are true:
1. The answer would materially change which options are viable or how they are evaluated.
2. The answer cannot be reasonably inferred from the requirement, the codebase, or context.

If the answer can be inferred, state it as an explicit assumption instead.
Do not ask questions whose answers would produce the same analysis regardless.
**If you must ask, ask everything in a single message — never one at a time.**

---

## Phase 2 — Explore the codebase

Read relevant existing code before designing:
- Find the affected domain area, existing entities, services, and repositories
- Understand the current architecture state of this part of the project
- Identify reusable components vs what needs to be created
- Note any existing technical debt that affects the solution

---

## Phase 3 — Propose exactly 3 options

Always present **exactly 3 options** — from most conservative to most sophisticated. Each must be genuinely different in approach, not just variations of the same idea.

For each option use this structure:

```
### Opción N — [Nombre]

**Resumen:** Una oración describiendo el enfoque.

**Cómo funciona:** Descripción breve del diseño.

**Ventajas:**
- ...

**Desventajas:**
- ...

**Riesgos técnicos:**
- Concurrencia: [¿condiciones de carrera posibles? ¿estado compartido?]
- Memory leaks: [¿recursos sin liberar, closures, suscripciones?]
- Rendimiento bajo carga: [¿cuellos de botella, N+1, queries sin límite?]
- Idempotencia: [¿es seguro reintentar la operación?]
- Escalabilidad: [¿qué se rompe primero al escalar?]

**Mejor para:** Cuándo esta opción es la elección correcta.
**Complejidad:** Baja / Media / Alta
**Reversibilidad:** Fácil de cambiar / Difícil de deshacer — explicar por qué
```

Evaluate all options across:
- Correctness and completeness
- Alignment with the project's current architecture
- Performance and resource usage under real load
- Testability
- Maintainability and readability
- Implementation effort

---

## Phase 4 — Recommendation

State which option you recommend and why, considering:
- The current state of the codebase (not the ideal state)
- The team's apparent conventions from the existing code
- Long-term maintainability vs implementation speed
- Which risks are acceptable given the context

If the project has architectural debt that affects the solution, mention it as `⚠️ Oportunidad de refactor` without making it a blocker.

---

## Phase 5 — Implementation plan

For the recommended option, produce a step-by-step plan:

```
## Plan de implementación — [Nombre de la opción]

### Pasos

1. [Nombre del paso]
   - Archivos a crear o modificar: `ruta/al/archivo.cs`
   - Qué implementar: descripción específica
   - Depende de: paso N (si aplica)

2. ...

### Resumen de archivos
| Acción | Archivo | Descripción |
|---|---|---|
| Crear | `Domain/Entities/X.cs` | ... |
| Modificar | `Application/Services/XService.cs` | ... |

### Estrategia de testing
- Unit tests necesarios para: [lista de handlers, servicios, lógica de dominio]
- Integration tests necesarios para: [lista de endpoints o repositorios]
- Caminos críticos a cubrir: [happy path, casos de error, edge cases, concurrencia]

### ADR requerido
[Sí — usar /user:adr-dotnet con la opción elegida / No]

### Actualización de README requerida
[Sí — nuevas env vars: X, Y / nuevo endpoint: Z / No]

### Complejidad estimada
[Pequeño < 2h / Medio ~medio día / Grande > 1 día — debería dividirse]

### Riesgos y preguntas abiertas
- [Cualquier incertidumbre o riesgo restante que pueda afectar el plan]
```

---

**No escribir ningún código hasta que el dev confirme el plan.**
Si el dev elige una opción diferente o la modifica, reconstruir el plan de implementación para esa opción antes de codificar.
Cuando se tome una decisión de arquitectura relevante, sugerir `/user:adr-dotnet` para documentarla.

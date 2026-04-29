# Plan implementation

Receive a requirement and produce a professional implementation plan before writing any code.

## Requirement
$ARGUMENTS

---

## Phase 1 — Understand before planning

Before proposing anything, ask all necessary questions to avoid building on wrong assumptions.

Identify what is unclear or ambiguous:
- Business rules and edge cases not specified
- Expected behavior under error conditions
- Volume / scale expectations (affects design decisions)
- Integration with existing components
- Non-functional requirements (latency, consistency, availability)
- Whether this is greenfield or modifying existing code

**Ask all questions in a single message** — do not ask one at a time. Wait for answers before proceeding to Phase 2.

If the requirement is clear enough to proceed without questions, state your assumptions explicitly instead.

---

## Phase 2 — Explore the codebase

Read relevant existing code before designing the solution:
- Find the affected domain area, existing entities, services and repositories
- Understand the current architecture state of this part of the project
- Identify reusable components vs what needs to be created
- Note any existing technical debt that affects the solution

---

## Phase 3 — Propose options

Present **at least two solution options**. For complex requirements, three.

For each option:

```
### Option N — Name

**Summary:** One sentence describing the approach.

**How it works:** Brief description of the design.

**Pros:**
- ...

**Cons:**
- ...

**Best for:** When this option is the right choice.
**Complexity:** Low / Medium / High
**Reversibility:** Easy to change later / Hard to undo
```

Evaluate options across:
- Correctness and completeness
- Alignment with the project's current architecture
- Performance and resource usage
- Testability
- Maintainability and readability
- Implementation effort

---

## Phase 4 — Recommendation

State which option you recommend and why, considering:
- The current state of the codebase (not the ideal state)
- The team's apparent conventions from the existing code
- Long-term maintainability vs implementation speed

If the project has architectural debt that affects the solution, mention it as a `⚠️ Refactor opportunity` without making it a blocker.

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
- Caminos críticos a cubrir: [happy path, casos de error, edge cases]

### ADR requerido
[Sí — decisión sobre X / No]

### Actualización de README requerida
[Sí — nuevas env vars: X, Y / nuevo endpoint: Z / No]

### Complejidad estimada
[Pequeño < 2h / Medio ~medio día / Grande > 1 día — debería dividirse]

### Riesgos y preguntas abiertas
- [Cualquier incertidumbre o riesgo restante que pueda afectar el plan]
```

---

**No escribir ningún código hasta que el dev confirme el plan.**
Si el dev elige una opción diferente, reconstruir el plan de implementación para esa opción antes de codificar.

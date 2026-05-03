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

Always present **exactly 3 options** — not superficial variations of the same idea.
Each must represent a genuinely different architectural approach with different implications.

For each option cover **every section below without exception**:

```
### Opción N — [Nombre — máximo 5 palabras descriptivas]

**Descripción técnica**
Cómo funciona a nivel de arquitectura: componentes, flujo de información, tecnologías y patrones.

**Ventajas**
Mínimo 4 ventajas técnicas concretas y específicas para este problema — no ventajas genéricas
del patrón, sino por qué son ventajas en este contexto.

**Desventajas y limitaciones**
Mínimo 4 desventajas reales. Honesto sobre los costos técnicos, operacionales y de mantenimiento.

**Comportamiento bajo carga y concurrencia**
¿Cómo se comporta con múltiples operaciones simultáneas?
¿Riesgo de condiciones de carrera, deadlocks o degradación?
¿Escala horizontalmente o tiene cuellos de botella inherentes?

**Comportamiento ante fallos**
¿Qué pasa si falla a mitad de operación? ¿El sistema queda consistente?
¿Es idempotente? ¿Soporta reintentos seguros?
¿Qué pasa si cae la BD, una cola, un servicio externo o la red?

**Impacto en persistencia y datos**
¿Qué cambios implica en el modelo de datos?
¿Requiere migraciones? ¿Afecta índices, transacciones o esquemas existentes?
¿Riesgo de pérdida o corrupción de datos?

**Impacto en otros servicios e integraciones**
¿Qué servicios dependientes se ven afectados?
¿Requiere cambios en contratos de API, eventos o mensajes?
¿Genera acoplamiento nuevo entre componentes?

**Complejidad de implementación**
Nivel: Baja / Media / Alta — justificación técnica y esfuerzo relativo vs las otras opciones.

**Complejidad operacional**
¿Qué implica operar esto en producción? ¿Monitoreo especial, configuración adicional?
¿Qué tan difícil es diagnosticar problemas en producción?

**Deuda técnica generada**
¿Qué compromisos técnicos conscientes implica? ¿Qué trabajo futuro genera?

**Reversibilidad**
¿Qué tan fácil es deshacer esta decisión?
¿Qué condición futura haría necesario revertirla?
¿Cuál sería el costo aproximado de revertirla una vez implementada?

**Cuándo es la opción correcta / cuándo NO lo es**
Contextos donde esta opción brilla y donde sería un error elegirla.
```

---

## Phase 4 — Comparative table

Compare the 3 options on a 1–5 scale (5 = best). Include a one-line justification per cell.

| Dimensión | Opción 1 | Opción 2 | Opción 3 |
|-----------|----------|----------|----------|
| Rendimiento bajo carga normal | | | |
| Rendimiento bajo carga alta | | | |
| Tolerancia a fallos | | | |
| Consistencia de datos | | | |
| Complejidad de implementación | | | |
| Complejidad operacional | | | |
| Escalabilidad horizontal | | | |
| Reversibilidad | | | |
| Costo de mantenimiento a largo plazo | | | |
| Velocidad de implementación | | | |

---

## Phase 5 — Pre-decision questions

Identify what is genuinely unresolved after the analysis and surface only those gaps.

**A question earns its place only if:**
- Its answer would change which option is viable or shift the recommendation — it is a real decision gate.
- It surfaces a risk or tradeoff the developer may not have weighed, so that whichever option
  they pick, they own the consequences consciously.

Do not include questions already answerable from the codebase, the requirement, or the analysis.
**If nothing is genuinely unresolved**, say so explicitly and proceed to the recommendation.
When questions are warranted, derive them from the specific options and risks surfaced — not from a template.

---

## Phase 6 — Recommendation

State which option you recommend and why, considering:
- The current state of the codebase (not the ideal state)
- The team's apparent conventions from the existing code
- Long-term maintainability vs implementation speed
- Which risks are acceptable given the context

If the project has architectural debt that affects the solution, mention it as `⚠️ Oportunidad de refactor` without making it a blocker.

**Do not recommend until the pre-decision questions from Phase 5 are answered,
unless the answers are clearly inferable from the codebase or context.**

---

## Phase 7 — Implementation plan

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

# Generate Architecture Decision Record

Document an architectural decision. Forces conscious, informed decision-making before
writing the ADR — not a transcription of what was analyzed, but a record of what was
understood, accepted, and why.

**Usage:**
- `/user:adr-dotnet <option chosen and any modifications>` — after running plan-dotnet or plan-implementation
- `/user:adr-dotnet <free description of the decision>` — standalone, without prior plan

## $ARGUMENTS

---

## Step 1 — Collect context

**If the conversation contains a prior plan output** (plan-dotnet or plan-implementation):
- Extract the 3 options that were proposed with their technical descriptions
- Identify which option the developer selected (from $ARGUMENTS) and any modifications they specified
- Carry forward the risk analysis already performed — do not discard it

**If there is no prior plan in the conversation:**
- Read `CLAUDE.md` and relevant existing files to understand the current state of the affected area
- Ask one focused question if the decision context is too vague to produce a meaningful ADR
- If enough context is available from $ARGUMENTS and the codebase, proceed without asking

---

## Step 2 — Diagnose before documenting

Before writing the ADR, assess what is known and identify which of these conditions apply.
**Only ask questions when a condition is present** — not as a default checklist.
Ask everything in a single message. Wait for answers before proceeding.

### Conditions that trigger questions

**Condition A — Missing or insufficient context**
The decision is too vague to produce a meaningful ADR.
*Ask:* What is the real engineering problem being solved? What constraints led to this decision?
What information was available — and what was missing — at the time of deciding?

**Condition B — Missing technical information**
Something critical for the ADR is unknown: failure behavior, idempotency, scaling limits,
affected services, data model impact.
*Ask only about what is actually missing.* Do not ask about what can be inferred
from the codebase, the prior plan, or the description already given.

**Condition C — The chosen option doesn't fully match the analyzed ones**
The developer modified an option, combined two, or chose something not in the original analysis.
*Ask:* Describe the variation precisely. What from the original option was kept and what changed?
Is there a new risk introduced by the modification that wasn't in the original analysis?

**Condition D — Signs the developer chose without solid foundations**
The justification is vague ("it seemed simpler", "I think it'll work"), a risk or consequence
was not mentioned that the prior analysis flagged as critical, or the choice contradicts
the constraints the developer themselves stated.
*Ask targeted questions about the specific gap:*
- "The analysis flagged [X] as a critical risk for this option. How are you handling it from the design?"
- "If this fails mid-operation, what state are the data left in and how does the system recover?"
- "If volume doubles, where does this solution break first?"
- "Are you aware that this option [specific critical consequence]? How does the design account for that?"

**Condition E — Options don't cover the problem well**
After reviewing the choice, it is apparent that none of the analyzed options fit cleanly,
or a better combination exists.
*Before closing the decision:*
"Is there a variation or combination of the analyzed options worth considering before committing?
For example, [specific combination relevant to this case]. If so, describe it briefly."

**If the developer proposes a new alternative or a valid combination, analyze it with the
same rigor as the original options before proceeding.**

**If none of the conditions above apply** — the decision is clear, well-justified, and
consistent with the prior analysis — proceed directly to Step 3.

---

## Step 3 — Determine the ADR number and path

```bash
ls docs/adr/ 2>/dev/null | sort | tail -1
```

- If the directory does not exist, create it: `mkdir -p docs/adr/`
- Increment the last number by 1, zero-padded to 4 digits (e.g. `0001`, `0042`)
- File name format: `NNNN-title-in-kebab-case.md`

---

## Step 4 — Generate the ADR

Write the file to `docs/adr/NNNN-title.md`. The tone must be technical, direct, and honest —
including known limitations and uncertainties, not only the benefits of the chosen path.

```markdown
# NNNN — [Decision title: short descriptive noun phrase, max 8 words]

**Date:** DD/MM/YYYY
**Status:** Accepted / Under Review / Proposed
**Author:** [git config user.name]

---

## 1. Contexto

El problema técnico real que motiva esta decisión — no el requerimiento funcional,
sino el problema de ingeniería de fondo. Incluir las restricciones conocidas
(técnicas, operacionales, de negocio), la información disponible al momento de decidir,
y las preguntas que quedaron sin respuesta. Escribir como si alguien llegara sin
ningún contexto previo. 3–5 oraciones.

---

## 2. Opciones evaluadas

### Opción 1 — [Nombre]
**Descripción:** [2–3 líneas de descripción técnica.]
**Trade-offs principales:**
- Ventajas relevantes para este caso: [lista]
- Desventajas relevantes para este caso: [lista]
**Por qué se descartó:** [razón específica para este contexto]

### Opción 2 — [Nombre]
**Descripción:** [2–3 líneas de descripción técnica.]
**Trade-offs principales:**
- Ventajas relevantes para este caso: [lista]
- Desventajas relevantes para este caso: [lista]
**Por qué se descartó:** [razón específica para este contexto]

### Opción 3 — [Nombre] *(elegida)*
**Descripción:** [2–3 líneas de descripción técnica.]
**Trade-offs principales:**
- Ventajas relevantes para este caso: [lista]
- Desventajas relevantes para este caso: [lista]
**Por qué se eligió:** [razón específica para este sistema, este equipo, este momento]

---

## 3. Decisión

**Se elige: Opción N — [Nombre]**

Por qué es la opción más adecuada para este contexto específico — no en abstracto.
Conectar la decisión con las restricciones concretas: carga esperada, arquitectura actual,
capacidad del equipo, riesgo tolerable. Si hay restricciones no técnicas que influyeron
(tiempo, conocimiento, deuda existente), documentarlas aquí — es válido y debe quedar registrado.

Si el dev modificó la opción base, describir exactamente qué se cambió y por qué.

3–5 oraciones.

---

## 4. Consecuencias

### Lo que mejora
- [Beneficios concretos que trae esta decisión en este contexto]

### Riesgos aceptados conscientemente
- [Qué podría salir mal, bajo qué condiciones, y por qué se acepta ese riesgo]
- [Qué deuda técnica se genera — cuándo y bajo qué condición habrá que pagarla]
- [Lo que más preocupa del camino elegido]

### Comportamiento ante fallo
- [Qué estado quedan los datos si el componente central falla a mitad de operación]
- [Cómo se recupera el sistema — idempotencia, reintentos, compensación]

### Qué se asume
- [Supuestos que deben ser verdaderos para que esta decisión sea correcta]
- [Ej: el volumen no superará X req/s en los próximos N meses]
- [Ej: el equipo conoce el patrón Y y puede mantenerlo sin introducción adicional]

---

## 5. Impacto

| Dimensión | Impacto | Detalle |
|---|---|---|
| Rendimiento | Bajo / Medio / Alto | [descripción con estimaciones si están disponibles] |
| Concurrencia | Bajo / Medio / Alto | [condiciones de carrera, locks, estado compartido] |
| Consistencia de datos | Eventual / Fuerte / Transaccional | [implicaciones] |
| Otros servicios | Sí / No | [qué servicios o equipos son afectados, qué contratos cambian] |
| Esquema de BD | Sí / No | [migraciones requeridas, cambios de índices, riesgo de pérdida de datos] |
| Infraestructura / Config | Sí / No | [nuevas env vars, appsettings, secretos, despliegue] |
| Escalabilidad horizontal | Sí / Con limitaciones / No | [cuello de botella si lo hay] |

---

## 6. Reversibilidad

**¿Es fácil deshacer esta decisión?** Fácil / Con esfuerzo / No — justificación técnica

**Condición concreta para revisar o revertir:**
- [Umbral o evento que indicaría que la decisión ya no es correcta]
- [Ej: si el tiempo de respuesta promedio supera X ms bajo carga Y]

**Costo estimado de reversión una vez en producción:**
- [Horas / días / semanas — y qué implica: migraciones, cambios de contrato, downtime]

**Lo que debe saber quien modifique esto en el futuro:**
- [Invariantes ocultos, acoplamiento no obvio, precondiciones que deben mantenerse]
- [Qué romperías sin darte cuenta si no sabes esto]
```

---

## Step 5 — Update PROJECT_STATUS.md (if it exists)

If `docs/PROJECT_STATUS.md` exists, add a line under the relevant section:

```
- Ver ADR-NNNN: [título de la decisión]
```

---

## Step 6 — Confirm

Present this summary:

```
✅ ADR generado: docs/adr/NNNN-titulo.md

Decisión documentada: [Opción elegida]
Reversibilidad: [Fácil / Con esfuerzo / No]
Impacto en BD: [Sí / No]
Impacto en config: [Sí / No]
Deuda técnica registrada: [Sí / No]

Próximos pasos:
  • Commitear junto con el código que implementa esta decisión
  • Actualizar README si hay nuevas env vars o endpoints
  • Ejecutar /user:plan-dotnet o /user:plan-implementation si aún no tienes el plan
```

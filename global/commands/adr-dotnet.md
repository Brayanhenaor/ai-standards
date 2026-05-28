# Generate Architecture Decision Record

Document an architectural decision. Forces conscious, informed decision-making before
writing the ADR — not a transcription of what was analyzed, but a record of what was
understood, accepted, and why.

**Usage:**
- `/user:adr-dotnet <option chosen and any modifications>` — after running plan-dotnet or plan-implementation
- `/user:adr-dotnet <free description of the decision>` — standalone, without prior plan

## $ARGUMENTS

---

## Tone

All communication with the developer must feel like a senior developer talking to a teammate —
not a review process, not an academic evaluation. Short sentences, direct questions, no jargon.

- Never phrase a question as a judgment or an accusation.
- Never use formal academic language ("conecta con los trade-offs", "adecuación técnica",
  "constraint técnico o de negocio").
- Ask one clear question at a time when possible. If you must ask more than one, keep them
  short and grouped naturally, not as a numbered checklist.
- When a follow-up is needed, acknowledge what the developer said first before redirecting.

**Contrast:**
❌ "Tu elección no conecta con los trade-offs del análisis. ¿Qué característica técnica de
   esta opción la hace la correcta para este contexto específico?"
✓ "¿Qué te hizo elegir esta sobre las otras?"

❌ "Esa razón describe conveniencia de implementación, no adecuación técnica."
✓ "Eso me dice que es más cómodo de implementar, pero lo que necesito entender es por qué
   encaja mejor con lo que el sistema necesita. ¿Qué te convenció técnicamente?"

❌ "El análisis identificó [riesgo] como el mayor riesgo de esta opción y no lo mencionaste."
✓ "Una cosa antes de cerrar: hay un riesgo importante con esta opción — [riesgo en una línea].
   ¿Cómo lo estás manejando, o lo estás aceptando a sabiendas?"

### When the developer seems confused

Detect confusion when: the developer says "no entiendo", "no sé", "¿qué significa X?",
gives an answer completely off-topic, asks the same thing back, or responds with very short
answers that suggest the question wasn't understood.

**Never repeat the same question with the same phrasing — that makes confusion worse.**

Instead:
1. Acknowledge what they said without judgment: "Entiendo, déjame explicarlo de otra forma."
2. Reframe using a concrete, real-world example from the codebase or business domain.
3. If the concept itself is unfamiliar, explain it in one sentence before asking again.
4. If needed, offer a binary or multiple-choice version of the question to lower the barrier:
   instead of an open question, give them two concrete scenarios and ask which applies.

When the confusion is about the options themselves (not the question), briefly re-explain
the relevant option in plain terms — what it does in practice, not its architectural name —
before continuing.

**The goal is for the developer to understand the decision they're making, not to pass a test.**
If re-explaining is needed, that's a normal part of the process, not a failure.

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

This condition fires when **ANY** of the following signals are present:

**D1 — Bare selection, no rationale**
$ARGUMENTS is just an option number or name ("opción 2", "la segunda", "option 3") with no
"because" or technical reasoning.
*Always triggers if the prior plan had high complexity: schema changes, multiple services
affected, reversibility rated "No" or "Con esfuerzo", or critical risks flagged.*
*Ask:* "Tu elección no conecta con los trade-offs del análisis. ¿Qué característica técnica
de esta opción la hace la correcta para este contexto específico — dado [constraint principal
del problema]? No en general, sino aquí."

**D1 special case — delegation to Claude's recommendation**
If the developer says "usa tu recomendación", "genera con lo que dijiste", "la que recomiendas",
"acepto tu sugerencia", or any equivalent — **this always triggers D1, no exceptions.**
The reasoning in the prior analysis is Claude's, not the developer's. The ADR must record
the developer's own understanding, not a repetition of Claude's analysis.
*Ask the same as D1, and additionally:* "¿Los riesgos críticos que el análisis identificó
para esta opción — [listar los marcados ⚠️ Crítico] — los entendiste y los aceptas
conscientemente? ¿O necesitas revisar alguno antes de cerrar la decisión?"

**D2 — Indecision signals**
The developer uses hedging language: "maybe", "I think", "probably", "not sure but",
"either option", "entre la 1 y la 2", "cualquiera de las dos". No ADR should be generated
while the developer is still deciding.
*Ask:* "Antes de documentar necesito que elijas una sola opción. ¿Cuál es y qué factor
técnico concreto del análisis la hace mejor para este caso?"

**D3 — Surface-level reasoning**
The justification references only implementation ease, familiarity, or convention
("menos código", "más simple", "ya lo conozco", "es lo que siempre hacemos", "es más rápido")
without connecting to the plan's actual trade-offs.
*Ask:* "Esa razón describe conveniencia de implementación, no adecuación técnica.
¿Qué trade-off concreto del análisis respalda esta elección? Conecta la decisión con
al menos un constraint técnico o de negocio del problema."

**D4 — Critical risk not acknowledged**
The prior analysis flagged a specific risk as critical or high for the chosen option,
and the developer's arguments don't acknowledge it at all.
*Ask:* "El análisis identificó [riesgo crítico específico] como el mayor riesgo de esta
opción y no lo mencionaste. ¿Cómo lo estás manejando desde el diseño?
¿O lo estás aceptando sabiendo exactamente qué implica?"

**D5 — Self-contradiction**
The developer chose an option that the plan explicitly marked as "NOT correct when
[condition X]" and that condition appears to apply to the current context.
*Ask:* "El análisis señaló que esta opción no es correcta cuando [condición X].
Esa condición parece aplicar aquí porque [razón concreta]. ¿Qué cambió en tu análisis
que hace que esta opción sea válida de todas formas?"

*Ask only about the specific signal detected — never all at once unless multiple signals
are present simultaneously.*

**These condition codes (D1–D5, A, B, C, E) are internal detection labels — never mention
them in responses to the developer.** Describe the problem in plain language, not by code.
Instead of "Esto activa D3", say "Esa razón describe conveniencia de implementación, no
adecuación técnica."

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

## Step 3 — Reversibility gate

Before determining the ADR number, assess the reversibility of the chosen option — from the
prior plan, the description, or the codebase analysis.

**If reversibility is "No":**
Pause and present explicitly before generating anything:

> "Esta decisión tiene reversibilidad **No** — una vez implementada en producción, revertirla
> implicaría [describir el costo real: migraciones, cambios de contrato de API, downtime,
> pérdida de datos, o refactor de múltiples servicios].
>
> ¿Confirmas que el equipo entiende y acepta esta condición de forma explícita?
> Responde 'confirmo' para continuar, o describe cómo ajustarías el diseño para mejorar la reversibilidad."

**Do not proceed to Step 4 until the developer explicitly confirms.**

**If reversibility is "Con esfuerzo":**
Surface una advertencia visible pero no bloqueante:

> "⚠️ Esta decisión tiene reversibilidad media — revertirla requeriría [costo estimado concreto].
> Continúa si lo tienes en cuenta."

**If reversibility is "Fácil":** proceed without interruption.

---

## Step 4 — Determine the ADR number and path

```bash
ls docs/adr/ 2>/dev/null | sort | tail -1
```

- If the directory does not exist, create it: `mkdir -p docs/adr/`
- Increment the last number by 1, zero-padded to 4 digits (e.g. `0001`, `0042`)
- File name format: `NNNN-title-in-kebab-case.md`

---

## Step 5 — Generate the ADR

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

## Step 6 — Update PROJECT_STATUS.md (if it exists)

If `docs/PROJECT_STATUS.md` exists, add a line under the relevant section:

```
- Ver ADR-NNNN: [título de la decisión]
```

---

## Step 7 — Confirm

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

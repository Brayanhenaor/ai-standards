---
name: adr
description: Generate an Architecture Decision Record after a real decision is made. Use when documenting an architectural choice — typically after the plan skill, or standalone. Forces conscious, justified decision-making (challenges the developer before writing) and emits the team's official ADR template, frozen.
---

# ADR — Architecture Decision Record

Record *what was understood, accepted, and why* — not a transcript of the analysis. Before writing,
make sure the developer actually owns the decision. The output template below is the team's
**official format — do not restructure it.**

> Output language follows the company default (Spanish labels, as below). Outside that profile, keep
> the same sections and structure but use the developer's language.

## Tone (challenge, don't interrogate)

Talk like a senior teammate: short, direct, no academic jargon. One clear question at a time;
acknowledge the answer before redirecting. For binary/2–4-option questions use `AskUserQuestion`.
If the developer seems confused, don't repeat the same phrasing — reframe with a concrete example and
explain the concept in one line. The goal is genuine understanding, not passing a test.

## Step 1 — Collect context

- **If a prior `plan` exists in the conversation:** carry forward the options, the chosen one (from
  `$ARGUMENTS`) with any modifications, and the risk analysis already done — don't discard it.
- **If not:** read `CLAUDE.md` and the affected code. Ask one focused question only if the context is
  too vague to produce a meaningful ADR; otherwise proceed.

## Step 2 — Challenge before documenting

Ask **only** when a real gap is present — never as a default checklist. Trigger questions when:

- **Bare selection** — `$ARGUMENTS` is just an option name/number with no reasoning (always ask if
  the decision is high-impact: schema changes, multiple services, low reversibility, critical risks).
- **Delegated to your recommendation** — "use yours", "the one you recommend". The ADR must record the
  *developer's* understanding, not your analysis. Ask their reasoning, and confirm they accept the
  flagged critical risks.
- **Indecision** — hedging ("maybe", "either one"). Don't write an ADR while they're still deciding.
- **Surface reasoning** — only ease/familiarity/convention, not connected to the trade-offs. Ask what
  convinced them *technically*.
- **Unacknowledged critical risk** — the analysis flagged one and they don't mention it. Surface it.
- **Self-contradiction** — they chose an option the analysis marked wrong for a condition that applies.
- **Options don't fit** — none fits cleanly or a better combination exists. Offer to explore it; if
  they propose a valid alternative, analyze it with the same rigor before proceeding.

Describe the gap in plain language — never expose internal labels.

## Step 3 — Reversibility gate

Assess reversibility of the chosen option.

- **"No":** stop and present the real cost of reverting (migrations, API contract changes, downtime,
  data loss). Require an explicit "confirmo" before generating.
- **"With effort":** show a visible, non-blocking warning with the estimated cost.
- **"Easy":** proceed.

## Step 4 — Number & path

`ls docs/adr/ 2>/dev/null | sort | tail -1` → increment, 4-digit zero-padded. Create `docs/adr/` if
absent. File: `NNNN-title-in-kebab-case.md`.

## Step 5 — Generate (frozen template)

Write `docs/adr/NNNN-title.md`. Technical, direct, honest — include limitations and uncertainties.

```markdown
# NNNN — [Decision title: short noun phrase, max 8 words]

**Date:** DD/MM/YYYY
**Status:** Accepted / Under Review / Proposed
**Author:** [git config user.name]
**Supersedes:** ADR-NNNN — [título] / —
**Related:** ADR-NNNN — [título] / —

---

## 1. Contexto

El problema técnico real que motiva esta decisión — no el requerimiento funcional, sino el problema
de ingeniería de fondo. Restricciones conocidas (técnicas, operacionales, de negocio), información
disponible al decidir, y preguntas sin respuesta. Escribir para alguien sin contexto previo. 3–5 oraciones.

---

## 2. Opciones evaluadas

Documentar todas las opciones evaluadas — no necesariamente 3. Marcar la elegida con *(elegida)*.

### Opción N — [Nombre] *(elegida / descartada)*
**Descripción:** [2–3 líneas de descripción técnica.]
**Trade-offs principales:**
- Ventajas relevantes para este caso: [lista]
- Desventajas relevantes para este caso: [lista]
**Por qué se descartó / eligió:** [razón específica para este contexto, equipo y momento]

_Repetir para cada opción evaluada._

---

## 3. Decisión

**Se elige: Opción N — [Nombre]**

Por qué es la más adecuada para este contexto específico — no en abstracto. Conectar con las
restricciones concretas: carga esperada, arquitectura actual, capacidad del equipo, riesgo tolerable.
Documentar también las restricciones no técnicas que influyeron (tiempo, conocimiento, deuda). Si se
modificó la opción base, describir qué se cambió y por qué. 3–5 oraciones.

---

## 4. Consecuencias

### Lo que mejora
- [Beneficios concretos en este contexto]

### Riesgos aceptados conscientemente
- [Qué podría salir mal, bajo qué condiciones, y por qué se acepta]
- [Qué deuda técnica se genera — cuándo y bajo qué condición habrá que pagarla]

### Comportamiento ante fallo
- [Estado de los datos si el componente central falla a mitad de operación]
- [Cómo se recupera el sistema — idempotencia, reintentos, compensación]

### Qué se asume
- [Supuestos que deben ser verdaderos para que la decisión sea correcta]

---

## 5. Impacto

| Dimensión | Impacto | Detalle |
|---|---|---|
| Rendimiento | Bajo / Medio / Alto | [descripción con estimaciones si están disponibles] |
| Concurrencia | Bajo / Medio / Alto | [condiciones de carrera, locks, estado compartido] |
| Consistencia de datos | Eventual / Fuerte / Transaccional | [implicaciones] |
| Otros servicios | Sí / No | [servicios/equipos afectados, contratos que cambian] |
| Esquema de BD | Sí / No | [migraciones, índices, riesgo de pérdida de datos] |
| Infraestructura / Config | Sí / No | [env vars, appsettings, secretos, despliegue] |
| Escalabilidad horizontal | Sí / Con limitaciones / No | [cuello de botella si lo hay] |

---

## 6. Reversibilidad

**¿Es fácil deshacer esta decisión?** Fácil / Con esfuerzo / No — justificación técnica

**Condición concreta para revisar o revertir:**
- [Umbral o evento que indicaría que la decisión ya no es correcta]

**Costo estimado de reversión una vez en producción:**
- [Horas / días / semanas — y qué implica: migraciones, cambios de contrato, downtime]

**Lo que debe saber quien modifique esto en el futuro:**
- [Invariantes ocultos, acoplamiento no obvio, precondiciones que deben mantenerse]
```

## Step 6 — Wrap up

If `docs/PROJECT_STATUS.md` exists, add `- Ver ADR-NNNN: [título]` under the relevant section. Then
confirm: file path, decision, reversibility, DB/config impact, whether tech debt was recorded, and
next steps (commit with the implementing code; update README if env vars/endpoints changed).

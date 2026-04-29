# Generate Architecture Decision Record

Generate a formal ADR based on the option chosen by the developer after running `/user:plan-dotnet`, or from a free-form description of the decision made.

**Usage:**
- `/user:adr-dotnet <option chosen and any modifications>` — after running plan-dotnet
- `/user:adr-dotnet <free description of the decision>` — standalone, without prior plan

## $ARGUMENTS

---

## Step 1 — Collect context

If the conversation contains a previous `/user:plan-dotnet` output:
- Extract the 3 options that were proposed
- Identify which option the developer selected and any modifications they specified in `$ARGUMENTS`
- Use the risk analysis already performed as input for sections 4 and 5

If there is no prior plan in the conversation:
- Read `CLAUDE.md` to understand project architecture and conventions
- Read relevant existing files to understand the current state of the affected area
- Ask one focused question if the decision context is too vague to produce a useful ADR

---

## Step 2 — Determine the ADR number and path

```bash
ls docs/adr/ 2>/dev/null | sort | tail -1
```

- If the directory does not exist, note it must be created: `mkdir -p docs/adr/`
- Increment the last number by 1, zero-padded to 4 digits (e.g. `0001`, `0042`)
- File name format: `NNNN-title-in-kebab-case.md`

---

## Step 3 — Generate the ADR

Write the file to `docs/adr/NNNN-title.md` using this exact structure:

```markdown
# NNNN — [Decision title: short noun phrase]

**Date:** DD/MM/YYYY
**Status:** Accepted
**Decided by:** [git config user.name]

---

## 1. Contexto

[El problema técnico real — no el requerimiento funcional. Describir el problema de diseño o
arquitectura que está detrás: por qué se necesita tomar una decisión aquí, qué restricciones
existen, qué podría salir mal si no se decide bien. 3–5 oraciones.]

---

## 2. Opciones evaluadas

### Opción 1 — [Nombre]
**Descripción:** [Una o dos oraciones.]
**Ventajas:** [lista]
**Desventajas:** [lista]

### Opción 2 — [Nombre]
**Descripción:** [Una o dos oraciones.]
**Ventajas:** [lista]
**Desventajas:** [lista]

### Opción 3 — [Nombre]
**Descripción:** [Una o dos oraciones.]
**Ventajas:** [lista]
**Desventajas:** [lista]

---

## 3. Decisión

**Se elige: Opción N — [Nombre]**

[Por qué es la más adecuada para este problema puntual — no en general. Conectar la decisión
con las restricciones específicas del contexto: carga esperada, arquitectura actual, capacidad
del equipo, riesgo tolerable. 3–5 oraciones.]

[Si el dev modificó la opción base, describir exactamente qué se cambió y por qué.]

---

## 4. Consecuencias

### Lo que mejora
- [Beneficios concretos que trae esta decisión]

### Riesgos y limitaciones
- [Qué podría salir mal, bajo qué condiciones]
- [Qué deuda técnica introduce o arrastra]

### Qué se asume
- [Supuestos que deben ser verdaderos para que esta decisión sea correcta]
- [Qué cambiaría la decisión si resultara incorrecto]

---

## 5. Impacto

| Dimensión | Impacto | Detalle |
|---|---|---|
| Rendimiento | Bajo / Medio / Alto | [descripción] |
| Concurrencia | Bajo / Medio / Alto | [condiciones de carrera, locks, estado compartido] |
| Memoria | Bajo / Medio / Alto | [allocations, leaks, retención de objetos] |
| Otros servicios | Sí / No | [qué servicios o equipos son afectados] |
| Esquema de BD | Sí / No | [migraciones requeridas, cambios de índices] |
| Configuración | Sí / No | [nuevas env vars, appsettings, secretos] |

---

## 6. Reversibilidad

**¿Es fácil deshacer esta decisión?** [Sí / Con esfuerzo / No]

**Qué asumo que es verdad hoy:**
- [Supuesto 1 — ej: el volumen no superará X req/s en los próximos 6 meses]
- [Supuesto 2 — ej: el equipo no crecerá más allá de N personas]

**Señales de que hay que revisar esta decisión:**
- [Condición o umbral que indicaría que la decisión fue incorrecta o ya no aplica]

**Plan de reversión si falla:**
- [Pasos concretos para deshacer o migrar si la decisión resulta equivocada]
```

---

## Step 4 — Update PROJECT_STATUS.md (if it exists)

If `docs/PROJECT_STATUS.md` exists, add a line under the relevant section referencing this ADR:

```
- Ver ADR-NNNN: [título de la decisión]
```

---

## Step 5 — Confirm

Present this summary to the dev:

```
✅ ADR generado: docs/adr/NNNN-titulo.md

Decisión documentada: [Opción elegida]
Reversibilidad: [Fácil / Con esfuerzo / No]
Impacto en BD: [Sí / No]
Impacto en config: [Sí / No]

Próximos pasos:
  • Commitear junto con el código que implementa esta decisión
  • Actualizar README si hay nuevas env vars o endpoints
  • Ejecutar /user:plan-dotnet si aún no tienes el plan de implementación
```

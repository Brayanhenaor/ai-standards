---
name: changelog
description: Generate a professional change-control document for specific commits or pending changes. Use when you need a formal record of a change for review, QA, or release — distinct from a git commit message. Emits the team's official change-control template, frozen.
---

# Changelog — change control document

Produce a formal change-control document. The structure below is the team's **official format — do
not restructure it.** This is a human-readable control document, not a `CHANGELOG.md` entry and not a
commit message.

> Output language follows the company default (Spanish, as below). Outside that profile, keep the
> same sections and structure but use the developer's language.

## Step 1 — Collect the changes

If `$ARGUMENTS` has commit SHAs:
```bash
git show <sha> --stat && git show <sha>
git diff <first>^..<last> && git diff <first>^..<last> --stat
git log --format="%H %s %an %ad" --date=short <range>
```

If empty (pending changes):
```bash
git log origin/HEAD..HEAD --oneline
git diff origin/HEAD..HEAD && git diff origin/HEAD..HEAD --stat
git diff --cached && git diff --cached --stat
```

## Step 2 — Analyze

Identify: what changed (files, areas, behavior), why (infer intent from messages/code), technical
scope (layers touched), risk surface (what could break), and how to validate.

## Step 3 — Generate (frozen template)

Output as a plain-text code block, professional tone, no emojis. If a section has nothing, write
"Ninguno"/"None" — never omit a section. Infer missing context from the code; leave no placeholders.

```
DOCUMENTO DE CONTROL DE CAMBIOS
================================
Proyecto:  [nombre del proyecto desde la carpeta o archivo .sln]
Fecha:     [fecha actual, formato: DD/MM/YYYY]
Versión:   [inferir del último tag o escribir "N/A"]
Commits:   [lista de SHAs, o "Cambios pendientes" si no se indicaron commits]
Autor:     [del git config user.name]


1. DESCRIPCIÓN DEL CAMBIO
--------------------------
[2–4 oraciones describiendo qué se modificó a nivel funcional. Escrito para un lector no
técnico. Explicar qué hace diferente el sistema después de este cambio.]


2. JUSTIFICACIÓN
----------------
[2–3 oraciones explicando por qué fue necesario. Inferir de los mensajes de commit, issues o
la naturaleza de los cambios. Enfocarse en la motivación de negocio o técnica.]


3. CAMBIOS TÉCNICOS REALIZADOS
-------------------------------
[Descripción detallada de lo que se hizo técnicamente. Organizado por área si abarca múltiples
capas. Explicar las decisiones tomadas y por qué. Para revisores técnicos.]


4. ARCHIVOS MODIFICADOS
-----------------------
[Listar cada archivo modificado con descripción de qué cambió. Formato:

  Path/To/File.cs
    - [qué cambió y por qué]
]


5. ARCHIVOS NUEVOS CREADOS
--------------------------
[Listar cada archivo nuevo con su propósito. "Ninguno" si no se crearon.

  Path/To/NewFile.cs
    - [propósito y responsabilidad de este archivo]
]


6. FUNCIONALIDAD PRESERVADA
---------------------------
[Comportamientos y flujos principales que permanecen sin cambios. Confirmar que la
funcionalidad existente no se rompió. Ser específico — endpoints, features, integraciones.]


7. IMPACTO Y RIESGOS
---------------------
[Riesgos potenciales: breaking changes, performance, dependencias, esquema de BD,
configuración, seguridad. Calificar cada riesgo como BAJO / MEDIO / ALTO y explicar la mitigación.]


8. VALIDACIÓN
-------------
[Instrucciones paso a paso para verificar el cambio. Unit tests a ejecutar, endpoints a llamar,
escenarios a probar, resultados esperados. Accionable para QA u otro desarrollador.]


9. ESTADÍSTICAS DEL CAMBIO
---------------------------
  Archivos modificados:  [N]
  Archivos creados:      [N]
  Archivos eliminados:   [N]
  Líneas agregadas:      [N]
  Líneas eliminadas:     [N]
  Commits incluidos:     [N]


10. OBSERVACIONES TÉCNICAS
--------------------------
[Notas para futuros mantenedores: limitaciones conocidas, trabajo pendiente, dependencias con
otros cambios, configuración por ambiente. "Ninguna" si no hay nada.]
```

Mix user-level explanations (sections 1, 2, 6) with technical detail (3, 4, 5). Format must be clean
enough to paste into Word or a ticketing system.

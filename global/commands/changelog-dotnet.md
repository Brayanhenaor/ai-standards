# Generate change control document

Generate a professional change control document based on specific commits or pending changes.

**Usage:**
- `/user:changelog-dotnet <commit1> <commit2> ...` — document for one or more specific commits
- `/user:changelog-dotnet` — document for all pending changes not yet pushed

---

## Step 1 — Collect the changes

If `$ARGUMENTS` contains commit SHAs:
```bash
# For each provided commit
git show <sha> --stat
git show <sha>

# Full diff across all provided commits
git diff <first-sha>^..<last-sha>
git diff <first-sha>^..<last-sha> --stat
```

If `$ARGUMENTS` is empty:
```bash
# All local commits not yet on remote
git log origin/HEAD..HEAD --oneline
git diff origin/HEAD..HEAD
git diff origin/HEAD..HEAD --stat

# Also include uncommitted staged changes if any
git diff --cached
git diff --cached --stat
```

Also run:
```bash
git log --format="%H %s %an %ad" --date=short <range>
```

---

## Step 2 — Analyze

Before writing the document, identify:

- **What changed**: which files, which functional areas, what behavior was added/modified/removed
- **Why it changed**: infer intent from commit messages, code context, and the nature of the changes
- **Technical scope**: which layers were touched (domain, application, infrastructure, API, config, tests, docs)
- **Risk surface**: what existing functionality could be affected
- **Validation approach**: how to verify the change works correctly

---

## Step 3 — Generate the document

Produce the document in Spanish using the following exact structure.

---

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
[2–4 oraciones describiendo qué se modificó a nivel funcional.
Escrito para un lector no técnico. Explicar qué hace diferente
el sistema después de este cambio.]


2. JUSTIFICACIÓN
----------------
[2–3 oraciones explicando por qué fue necesario este cambio.
Inferir de los mensajes de commit, referencias a issues o la
naturaleza de los cambios. Enfocarse en la motivación de negocio
o técnica.]


3. CAMBIOS TÉCNICOS REALIZADOS
-------------------------------
[Descripción detallada de lo que se hizo técnicamente. Organizado
por área si el cambio abarca múltiples capas. Explicar las decisiones
tomadas y por qué. Esta sección es para revisores técnicos.]


4. ARCHIVOS MODIFICADOS
-----------------------
[Listar cada archivo modificado con descripción de qué cambió.
Formato:

  Path/To/File.cs
    - [qué cambió y por qué]

  Path/To/Another.cs
    - [qué cambió y por qué]
]


5. ARCHIVOS NUEVOS CREADOS
--------------------------
[Listar cada archivo nuevo con descripción de su propósito.
Escribir "Ninguno" si no se crearon archivos.

  Path/To/NewFile.cs
    - [propósito y responsabilidad de este archivo]
]


6. FUNCIONALIDAD PRESERVADA
---------------------------
[Listar los comportamientos y flujos principales que permanecen
sin cambios. Confirmar que la funcionalidad existente no se rompió.
Ser específico — mencionar nombres de endpoints, features o puntos
de integración.]


7. IMPACTO Y RIESGOS
---------------------
[Describir los riesgos potenciales introducidos por este cambio.
Considerar: breaking changes, impacto en performance, cambios de
dependencias, cambios en esquema de base de datos, cambios de
configuración, implicaciones de seguridad.
Calificar cada riesgo como BAJO / MEDIO / ALTO y explicar la mitigación.]


8. VALIDACIÓN
-------------
[Instrucciones paso a paso para verificar que el cambio funciona.
Incluir: unit tests a ejecutar, endpoints a llamar, escenarios a probar,
resultados esperados. Debe ser accionable para QA u otro desarrollador.]


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
[Notas técnicas adicionales relevantes para futuros mantenedores.
Incluir: limitaciones conocidas, trabajo pendiente, dependencias con
otros cambios, configuración requerida por ambiente, etc.
Escribir "Ninguna" si no hay nada que agregar.]
```

---

## Output rules

- Professional tone — no emojis, no informal language
- Mix user-level explanations (sections 1, 2, 6) with technical detail (sections 3, 4, 5)
- Clean formatting suitable for copying into Word or a ticketing system
- If a section has nothing to report, write "None" — do not omit the section
- Infer missing context (justification, risks) from the code — do not leave placeholders
- Output the document as a plain text code block so it is easy to copy

# Structured debugging

Apply scientific method to debug a compilation or runtime error. One hypothesis. One change. Verify. Never guess.

**Usage:**
- `/user:debug-dotnet <error message or description>` — paste the error or describe what's failing
- `/user:debug-dotnet` — use whatever error is visible in the current context

## $ARGUMENTS

---

## RULE ZERO — Do not touch any code until Step 3

Every failed debugging attempt happens because a change was made before the problem was fully understood. Read everything first.

---

## Step 1 — Collect the full picture

### 1a — Get the complete error

If a compilation error:
```bash
dotnet build 2>&1
```
Do not filter. Read the full output — multiple errors often have a root cause that generates cascading symptoms. Fix the first error in the list, not all of them simultaneously.

If a runtime error: ask the user for the **complete** stack trace, not just the exception message. The relevant frame is usually not the top one.

If a test failure:
```bash
dotnet test --logger "console;verbosity=detailed" 2>&1
```

### 1b — Read every file and line referenced in the error

For each `File.cs(line, col)` in the error output:
- Read the file at that line plus 10 lines of surrounding context
- Read the method signature, class declaration, and any relevant interface

Do not skip this. The error message says *where* but not always *why*.

### 1c — Get recent changes that may have introduced this

```bash
git diff HEAD
git diff HEAD --stat
git stash list
```

A bug introduced by a recent change is almost always in the diff. Look there first.

### 1d — Check for related or prior errors

- Are there multiple compilation errors? The first one is the root; others are often cascades.
- Is there a similar pattern elsewhere in the codebase that works? Compare it to the broken one.
- Does the error happen always or only under specific conditions?

---

## Step 2 — Form explicit hypotheses BEFORE touching code

Write out 2–3 hypotheses ranked by likelihood. Each must include:
- The specific cause
- The evidence that supports it
- What a fix would look like

```
Hipótesis 1 (más probable): [causa específica]
  Evidencia: [por qué el error y el código apuntan aquí]
  Fix implicado: [qué cambiaría exactamente]

Hipótesis 2: [causa alternativa]
  Evidencia: [...]
  Fix implicado: [...]

Hipótesis 3 (menos probable): [...]
  Evidencia: [...]
  Fix implicado: [...]

→ Empezando con hipótesis 1 porque: [razón]
```

State which hypothesis you are testing and why before making any change.

---

## Step 3 — Make exactly ONE targeted change

- Change the minimum necessary to test hypothesis 1
- Do not refactor, rename, reorganize, or "improve" anything else while debugging
- Do not fix multiple hypotheses simultaneously — you will not know which one worked
- State explicitly: *"Este cambio prueba la hipótesis 1 modificando X porque Y"*

---

## Step 4 — Verify

After the change:

```bash
dotnet build 2>&1        # for compilation errors
dotnet test 2>&1         # for test failures
```

Or ask the user to run the application and reproduce the original scenario.

**If the error is resolved:**
- Confirm which hypothesis was correct and why the fix works
- Check that no new errors were introduced
- Done

**If the error persists or new errors appear:**
- State explicitly: *"La hipótesis 1 era incorrecta. Observación: [lo que el resultado revela]"*
- Revert the change completely before proceeding
- Move to hypothesis 2

---

## Step 5 — If all hypotheses fail

Do not guess. Do not make random changes. Instead:

1. Re-read the error message looking for something missed the first time
2. Search the codebase for the specific symbol, method, or type mentioned in the error
3. Check if the issue is environmental (missing package, wrong SDK version, missing env var):
   ```bash
   dotnet --version
   dotnet restore
   dotnet list package --outdated
   ```
4. Formulate new hypotheses from what was learned — and start Step 2 again

---

## Absolute constraints

- **Never make more than one change per iteration** — if you change two things and the error disappears, you don't know which one fixed it and you've introduced an unverified change
- **Never assume a fix worked** — always verify with build/test/run
- **Never move to the next hypothesis without reverting the previous attempt** — stacked failed fixes create a new problem on top of the original
- **Never "clean up" while debugging** — refactoring during debugging masks what actually fixed the issue
- **If three hypotheses all fail, stop and ask** — do not enter a guessing loop; request more information from the user

# Pre-PR gate

Run before opening every pull request. Orchestrates all quality checks across the branch changes and produces a single actionable checklist. Does NOT auto-run other commands — it reports what needs to be done and which command to invoke.

**Usage:**
- `/user:gate-dotnet` — run the pre-PR gate on all changes in the current branch

---

## Step 0 — Collect branch state

```bash
git diff main...HEAD --stat
git diff main...HEAD --name-only
git log main...HEAD --oneline
git status
```

Read `CLAUDE.md` to understand project architecture and expectations.

---

## Step 1 — Gate dimensions

Evaluate each dimension in order. For each one, output a status: ✅ clean / ⚠️ needs attention / ❌ blocker.

---

### 1. Build

```bash
dotnet build --no-restore -v quiet 2>&1 | grep -E "(error|warning CS)"
```

- ❌ Any compilation error → block, fix before anything else
- ⚠️ Compiler warnings → review each one
- ✅ Zero errors and zero warnings

---

### 2. Tests

Identify test files added or modified. Check:

```bash
dotnet test --no-build -v quiet 2>&1 | tail -10
```

- ❌ Any failing test
- ⚠️ New business logic or handlers added without corresponding test files → run `/user:test-dotnet`
- ⚠️ Test coverage gap: new public method with no test
- ✅ All tests pass, coverage for new code exists

---

### 3. Code review

Analyze the diff mentally across all dimensions (correctness, architecture, concurrency, performance, design):

- ❌ Captive dependency (Scoped in Singleton), async void, .Result/.Wait() deadlock risk, hardcoded secrets
- ❌ Business logic in controller, missing [Authorize] on new endpoint
- ⚠️ Missing .AsNoTracking() on read queries, unbounded collection result, magic strings
- ⚠️ Long method, nested conditionals, duplicated logic
- ✅ Clean across all dimensions → run `/user:review-dotnet` for deep dive if uncertain

**If the branch touches: authentication, authorization, input validation, secrets, CORS, or external APIs:**
→ Auto-escalate to `/user:security-dotnet` (mark as ⚠️ until done)

---

### 4. Security (conditional)

Check if any changed file matches:
- `*Auth*.cs`, `*Jwt*.cs`, `*Token*.cs`, `*Policy*.cs`, `*Permission*.cs`
- Controllers with new endpoints
- Any hardcoded string that looks like a credential

If yes:
- ⚠️ → run `/user:security-dotnet` before merge
- Report which files triggered this

If no security-relevant changes:
- ✅ Security check not required for this diff

---

### 5. Migrations (if any)

Check for files in `**/Migrations/**`:

- ❌ NOT NULL column added without nullable + backfill + constraint pattern
- ❌ Down() is empty or throws
- ⚠️ Rename without expand-contract
- ⚠️ Data migration mixed with schema migration
- ✅ Safe → run `/user:migrate-dotnet` for detailed analysis

---

### 6. Messaging (conditional)

Check if any changed file matches `*Consumer*.cs`, `*Event*.cs`, `*Saga*.cs`, `*Publisher*.cs`:

- ❌ Consumer without idempotency check
- ❌ SaveChangesAsync + Publish without outbox
- ⚠️ Missing retry/dead-letter configuration
- ✅ Clean → run `/user:messaging-dotnet` for deep dive if uncertain

---

### 7. Commit message

Check the last commit message on this branch:

```bash
git log main...HEAD --format="%s" | head -5
```

- ❌ Does not follow Conventional Commits (`feat:`, `fix:`, `refactor:`, etc.)
- ❌ Subject over 72 characters
- ⚠️ Missing scope when scope would add clarity
- ✅ Follows format → if not, run `/user:commit-dotnet`

---

### 8. Documentation (conditional)

Check if any of these changed:
- New appsettings keys or env vars → README updated?
- New or modified endpoints → README / OpenAPI annotations updated?
- Architectural decision made → ADR created in `/docs/adr/`?
- New technical debt identified → `PROJECT_STATUS.md` updated?

- ⚠️ Any of the above missing → note which one
- ✅ All documentation up to date → or no doc-triggering changes

---

### 9. Change control document (conditional)

For branches going to production environments or containing significant changes:

- Does the branch have > 5 files changed OR any migration OR any new endpoint?
  → ⚠️ Run `/user:changelog-dotnet` if a change control document is required
- Small fix (1-2 files, no migration, no API change)?
  → ✅ Changelog not required

---

## Step 2 — Output

```
## Pre-PR Gate — [branch name]

### Resumen ejecutivo
[One sentence: "Branch ready for merge" / "N blockers, M items to resolve" / "N blockers — do not merge"]

---

### ✅ Build
[Status + detail if any warning]

### ✅ / ⚠️ / ❌ Tests
[Status + which tests are failing / missing]

### ✅ / ⚠️ / ❌ Code review
[Summary of findings — for full detail run: /user:review-dotnet]

### ✅ / ⚠️ / ❌ Security
[Status — triggered: yes/no — if yes: run /user:security-dotnet]

### ✅ / ⚠️ / ❌ Migrations
[Status — if present: run /user:migrate-dotnet for full analysis]

### ✅ / ⚠️ / ❌ Messaging
[Status — if present: run /user:messaging-dotnet for full analysis]

### ✅ / ⚠️ / ❌ Commit message
[Status — if not compliant: run /user:commit-dotnet]

### ✅ / ⚠️ Documentation
[What's missing if anything]

### ✅ / ⚠️ Change control
[Required / not required — if required: run /user:changelog-dotnet]

---

### Checklist de acciones
[Only items that need action — empty if all ✅]

- [ ] ❌ Fix failing test `[TestName]`
- [ ] ⚠️ Run `/user:security-dotnet` — changed files: `AuthController.cs`, `JwtService.cs`
- [ ] ⚠️ Run `/user:commit-dotnet` — current message does not follow Conventional Commits
- [ ] ⚠️ Update README — new env var `PAYMENT_API_KEY` not documented

### Veredicto
[One of:]
✅ Listo para PR — todos los checks verdes
⚠️ Resolver items marcados antes del PR
🚫 Bloqueantes críticos — no abrir PR hasta resolver ❌
```

---

## Output rules

- The gate is a coordinator, not a deep reviewer — it flags and delegates
- Never block on ⚠️ alone — only ❌ blockers require resolution before PR
- Each ⚠️ or ❌ item must include exactly which command to run or what to fix
- The "Checklist de acciones" must be copy-pasteable into a PR description or issue
- If uncertain whether a dimension is clean, recommend running the full expert command rather than guessing
- This command runs fast — it gives a high-confidence signal, not a complete audit

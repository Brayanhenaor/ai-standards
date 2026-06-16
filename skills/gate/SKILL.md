---
name: gate
description: Pre-PR gate — run the full readiness check before opening a pull request. Use when the developer is about to push or open a PR, or asks "is this ready?". Orchestrates build, tests, review, security, migration safety, and commit/doc hygiene into one go/no-go verdict.
---

# Gate — pre-PR readiness

One orchestrated pass that answers a single question: **is this change ready to open as a PR?**
Compose the other skills; don't re-implement them. Report a clear go / no-go with the blockers.

## Run, in order

1. **Build & tests** (`verify`) — it compiles and the test suite passes. A red build is an instant
   no-go.
2. **Review** (`review --diff`) — clean-code and correctness audit of the change. Surface
   `[CRITICAL]` findings as blockers.
3. **Security** (`security-audit --diff`) — any `CRITICAL`/`HIGH` finding is a blocker.
4. **Migration safety** (`migrate`) — if the diff touches schema/migrations, check it's safe and
   reversible.
5. **Hygiene** — secrets/`.env`/generated files not staged; commits follow Conventional Commits;
   README/docs updated if config, env vars, endpoints, or deployment changed.

## Verdict

Report concisely:

```
GATE: GO  /  NO-GO

✓ build & tests        ✓/✗
✓ review (clean code)  ✓/✗   — N critical
✓ security             ✓/✗   — N critical/high
✓ migration safety     ✓/✗ / n/a
✓ hygiene & docs       ✓/✗

Blockers:
- [the specific things that must be fixed before the PR]
```

- **NO-GO** if any blocker exists. List exactly what to fix — don't soften it.
- **GO** only when all checks pass. Don't wave a change through to be agreeable; the gate's value is
  that it says no when it should.
- Don't fix things here — gate reports. Hand specific fixes back to the relevant skill.

Reply in the developer's language; keep code and identifiers in English.

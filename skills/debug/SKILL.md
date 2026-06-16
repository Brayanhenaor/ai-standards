---
name: debug
description: Debug a compilation or runtime error methodically instead of guessing. Use whenever the developer reports an error, a failing test, or unexpected behavior. Enforces collect → hypothesize → one change → verify, and refuses to thrash through random fixes.
---

# Debug

Debugging is investigation, not trial-and-error. Apply this protocol automatically the moment an
error or unexpected behavior appears — don't wait to be asked, and don't start editing before you
understand.

## The protocol

1. **Collect before acting.** Read the full error output, every file and line it references, and the
   recent change (`git diff HEAD`). Never propose a fix without reading the exact location the error
   points to. Reproduce the failure if you can — a repro you can run is the ground truth.
2. **State one hypothesis, explicitly.** Before touching code, say what you believe the cause is and
   *why*. If genuinely unsure, list 2–3 ranked hypotheses — but commit to testing the top one first.
3. **One change per iteration.** Make the minimum change to test hypothesis #1. Do not fix several
   things at once. Do not refactor while debugging — that hides which change mattered.
4. **Verify before moving on.** Re-run. If it's fixed, confirm with the real command/test and stop.
   If not, state what the attempt *revealed*, revert it, and move to the next hypothesis.
5. **Never guess in a loop.** If two hypotheses fail, stop and gather more information — logs, a
   smaller repro, the developer's input — rather than trying random changes. Thrashing is a signal to
   step back, not to try harder.

## Discipline

- **Read the actual error, not a remembered shape of it.** The message and stack trace usually name
  the cause; don't pattern-match past them.
- **Change one variable at a time.** If you altered two things and it works, you've learned nothing.
- **Distinguish symptom from cause.** A null reference is a symptom; *why* it's null is the bug. Fix
  the cause, not the crash site.
- **Keep the fix minimal and clean.** Once the cause is found, fix it at the right level — no
  unrelated changes riding along. Then hand off to `verify` to confirm.
- **Be honest about uncertainty.** If you don't yet know the cause, say so and say what you'd check
  next — don't present a guess as a diagnosis.

Reply in the developer's language; keep code and identifiers in English.

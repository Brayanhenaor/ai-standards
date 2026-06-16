---
name: verify
description: Verify that a change actually works before claiming it is done. Use after implementing or fixing something, before reporting completion. Runs the project's real build, tests, linters, or the app itself and reads the actual output — never assumes success from "the code looks right."
---

# Verify (with teeth)

"Done" means *verified*, not *written*. Code that looks right is a hypothesis; the build and the
tests are the evidence. Never tell the developer something works until you have checked it — and if
you couldn't check it, say so explicitly.

## The loop

1. **Decide what "works" means** for this change: it compiles, the tests pass, the linter is clean,
   the endpoint returns the right thing, the bug no longer reproduces.
2. **Find the project's real commands.** Don't invent them. Look in `package.json` scripts, the
   `Makefile`/`justfile`, CI config, `*.csproj`/`*.sln`, `pyproject.toml`, the README, etc. Use what
   the project actually uses.
3. **Run them and read the output.** Build, then tests, then lint/format/type-check as applicable.
   Read the actual result — exit code and messages — not just whether something ran.
4. **On failure:** report the real error, form one hypothesis, make the minimum fix, and re-run.
   Don't stack speculative changes. Don't loop blindly — if two hypotheses fail, stop and surface
   what you've learned.
5. **On success:** state exactly what you ran and what passed. No vague "should work."

## Match the verification to the change

- **Pure logic / unit-level:** run the unit tests covering it; add one if the path is uncovered.
- **Behavior / integration:** run integration tests or exercise the real path (HTTP call, CLI run).
- **Bug fix:** reproduce the bug *first* so you know the repro works, then confirm the fix removes it.
- **Refactor:** the existing tests must stay green — that's the safety net. If there are none,
  consider a characterization test before changing behavior-bearing code.
- **UI/visual:** run the app and observe; don't assert pixels from reading code.

## Honesty rules

- If you didn't run it, don't claim it passes. Say "not verified" and why (no test, no runnable env,
  out of scope).
- If tests fail, report it plainly with the output — never bury or soften a failure.
- If a step was skipped, say which and why.
- Distinguish "I ran X and it passed" from "I believe this is correct." They are not the same claim.

This skill backs the self-verification every Supercode skill owes the developer: question your own
output, then prove it.

---
name: test
description: Generate or improve unit and integration tests for code. Use when asked to write tests, add coverage, or test a change. Follows the project's existing test stack and conventions, covers the paths that matter, tests behavior not implementation, and verifies the tests actually run.
---

# Test

Write tests that pin behavior and would actually catch a regression — not tests that restate the
implementation or chase a coverage number.

## 1. Match the project

- Use the project's existing test framework, assertion library, and substitute/mock library — detect
  them from the test projects, don't impose your own. Stack specifics (e.g. .NET: xUnit + free
  assertions + NSubstitute) come from the active pack's `testing.md`.
- Follow the existing naming and structure conventions. Mirror how the project already tests.
- If the project has no fakes/assertion library and a path genuinely needs one, propose the pack's
  standard (license + consent) rather than hand-rolling test doubles.

## 2. Test behavior, through the public surface

- Test what the unit *does* (its observable behavior and contract), not its private internals.
  Private methods are exercised through the public API.
- One scenario per test; arrange/act/assert clearly separated. A test name states method, scenario,
  and expected result.
- Build the system-under-test once; substitute its collaborators. Only assert interactions when the
  interaction *is* the behavior under test.

## 3. Cover the paths that matter

Happy path, plus the failure and edge cases that apply: not-found, already-exists, validation
failure, business-rule violation, dependency failure (propagates correctly), empty collection,
boundary values. Don't pad with trivial tests of framework or DTO behavior.

## 4. Pick the right level

- **Unit** for logic in isolation (substitute I/O).
- **Integration** for wiring, persistence, and endpoints — exercise the real path; don't mock the
  database. Control time with a fake time provider rather than real clocks.

## 5. Verify

Run the tests you wrote (`verify`) — they must pass, and a new test for a bug should fail *before* the
fix. Don't claim coverage you didn't run. Reply in the developer's language; tests and identifiers in
English.

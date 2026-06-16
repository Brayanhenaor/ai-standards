---
name: concurrency
description: Analyze code for concurrency correctness — race conditions, deadlocks, shared mutable state, and async/await pitfalls. Use when writing or reviewing async code, background work, shared caches/singletons, or anything touched by more than one thread or request. Reports concrete hazards, not vague warnings.
---

# Concurrency lens

Concurrency bugs hide until load finds them. Apply this lens whenever code is reachable from more than
one thread or request at once — and report concrete, reproducible hazards with the fix.

## What to look for

- **Shared mutable state.** Any field, static, dictionary, or cache mutated from multiple
  threads/requests without synchronization is a race. Prefer immutability; if state must be shared,
  guard it (lock, concurrent collection, atomic) or isolate it per unit of work.
- **Check-then-act races.** `if (!cache.has(k)) cache.set(k, …)` run concurrently does the work N
  times — or corrupts state. Use atomic get-or-add / a lock with double-check.
- **Deadlocks.** Two locks acquired in different orders; blocking on async from sync code; a bounded
  pool waiting on itself. Establish a lock order; never mix blocking and async.
- **Async correctness.** Don't block on async (`.Result`/`.Wait()`/`.get()`), don't fire-and-forget
  without handling failures, flow cancellation through, and don't capture state that can change
  under you mid-await.
- **Lifetime/captivity.** A long-lived object holding a per-request/short-lived one shares it across
  requests — a classic source of data bleed. (In .NET: captive dependencies — see the dotnet pack's
  `di-and-config.md`.)
- **Non-atomic compound operations.** Read-modify-write on a shared counter/collection needs to be
  atomic, not three separate steps.

## How to report

For each hazard: where it is, **the interleaving that breaks it** (be concrete — "if request A and B
hit this line between the check and the set…"), the impact, and the minimal correct fix. If you
can't construct a failing interleaving, it may not be a real hazard — say so rather than flag noise.

Stack specifics (memory model, synchronization primitives, async idioms) come from the active pack;
the reasoning above is language-agnostic.

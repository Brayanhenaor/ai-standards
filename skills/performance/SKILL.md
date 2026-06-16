---
name: performance
description: Analyze code for performance and efficiency problems — algorithmic complexity, N+1 queries, needless allocations, blocking I/O, and missing caching. Use when reviewing hot paths, data-access code, loops over large data, or endpoints returning collections. Grounds findings in evidence, not premature optimization.
---

# Performance lens

Make it correct and clean first; make it fast where it measurably matters. This lens finds *real*
inefficiencies — not micro-optimizations that trade readability for nothing.

## What to look for

- **Algorithmic complexity.** Nested loops over large inputs (O(n²)), repeated linear scans that a
  set/map makes O(1), sorting when a single pass would do. Fix the algorithm before anything else —
  it dwarfs micro-tuning.
- **N+1 data access.** A query inside a loop, or lazy-loading per item. Batch it: one query with a
  join/projection, or load-then-map in memory. (In .NET/EF: project with `Select`, `AsNoTracking`,
  split queries — see the dotnet pack's `data-ef.md`.)
- **Over-fetching.** Selecting whole rows/objects when a few fields suffice; returning unbounded
  collections instead of paginating; loading a list to compute a count.
- **Allocations on hot paths.** Building strings in loops, materializing large sequences eagerly,
  boxing, copying buffers. Stream instead of buffering when volume is large.
- **Blocking & chatty I/O.** Synchronous I/O on request threads; many small round-trips where one
  batched call works; missing connection reuse/pooling.
- **Missing/incorrect caching.** Recomputing expensive deterministic results; or caching things that
  shouldn't be cached. (See the `caching` guidance.)

## Discipline

- **Evidence over instinct.** Flag the complexity/N+1/allocation you can *see*; for anything subtler,
  recommend measuring (profile, query plan, benchmark) before changing — don't guess at hotspots.
- **Don't sacrifice clean for fast** unless there's a measured need. Premature optimization is its own
  smell, and over-engineering in disguise.
- For each finding: the cost (where, how it scales), the evidence, and the fix — and whether it's
  worth doing now or only at scale.

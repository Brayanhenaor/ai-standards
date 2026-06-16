---
name: architect
description: Senior-architect lens for decisions that cross services, layers, or systems. Use when designing a feature that spans boundaries, choosing between architectural approaches, adding an external integration, or anything affecting scalability, availability, or operational complexity. Surfaces trade-offs and failure modes before code is written.
---

# Architect lens

Apply when a decision reaches beyond a single class — across services, layers, data stores, or system
boundaries. The job is to surface trade-offs and failure modes early, when they're cheap to change.

## What to examine

- **Boundaries & coupling.** Are responsibilities in the right place? Does this change couple things
  that should evolve independently, or leak one layer's concerns into another? Dependencies should
  point inward (toward stable policy), not outward toward detail.
- **Scalability.** What happens at 10×/100× load or data? Where's the bottleneck — CPU, a shared DB,
  a single writer, a lock? Does the design scale horizontally, or does some shared state prevent it?
- **Availability & fault tolerance.** What fails when a dependency is slow or down? Is failure
  contained (timeouts, circuit breakers, bulkheads, graceful degradation) or does it cascade? No
  single point of failure on a critical path.
- **Distributed-systems consistency.** Crossing a process boundary trades a guarantee for a
  trade-off. Is strong consistency actually needed, or is eventual fine? How are partial failures,
  retries, and duplicate delivery handled (idempotency, outbox, sagas)?
- **Data ownership.** One owner per piece of data. Are you reaching into another service's store?
  Is a shared database coupling services that should be independent?
- **Operational complexity.** Every moving part is something to deploy, monitor, and debug at 3am.
  Is the added complexity justified by a real, present need — or is it architecture astronautics?

## Discipline

- **Simplest architecture that meets real requirements.** Don't add services, queues, caches, or
  layers for scale or flexibility nobody has asked for — that's over-engineering at the system level.
  A modular monolith often beats premature microservices.
- Present options with trade-offs (complexity, scalability, availability, cost, operability) and a
  recommendation. Name the failure modes explicitly.
- Flag anything worth an ADR. Hand the chosen approach to `plan` for step breakdown.

---
name: domain
description: Domain-modeling lens (DDD) for entities, aggregates, value objects, and business rules. Use when adding or changing domain concepts, enforcing invariants, designing repository boundaries, or naming things in the domain. Pushes for a model that protects its invariants and speaks the business's language.
---

# Domain lens

Good domain code makes illegal states unrepresentable and speaks the business's language. Apply this
lens when modeling concepts, encoding rules, or naming domain things.

## What to examine

- **Aggregate boundaries.** An aggregate is the unit of consistency — the set of objects that must
  change together under one invariant, behind one root. Keep them **small**; reference other
  aggregates by id, not by object. A transaction touches one aggregate; cross-aggregate changes go
  through events/eventual consistency.
- **Invariant enforcement.** Business rules live *inside* the model and are enforced at every entry
  point — not in a service that callers might bypass, and not only in the UI. An object should be
  impossible to construct or mutate into an invalid state.
- **Value objects over primitives.** Replace bare strings/ints that carry meaning and rules
  (`Money`, `Email`, `Quantity`) with value objects — immutable, self-validating, compared by value.
  This kills primitive obsession and centralizes the rules. (See core `smells.md`.)
- **Rich behavior, not anemic data.** Entities expose intention-revealing operations
  (`order.Cancel()`), not public setters that let callers do whatever. Behavior belongs with the data
  it governs (tell-don't-ask).
- **Ubiquitous language.** Code names match the business's real vocabulary, consistently, everywhere.
  A mismatch between the model and how the domain experts speak is a design smell — fix the name or
  fix the understanding.
- **Bounded contexts.** The same word can mean different things in different contexts (a "Customer"
  in billing vs support). Don't force one shared model across contexts; let each own its meaning.

## Discipline

- Model only what the domain actually requires now — don't build a generic rules engine for two
  rules (over-engineering). Depth where the business is complex; simplicity where it isn't.
- For each finding: the concept at stake, the invariant or language at risk, and the modeling change.
- Keep persistence/framework concerns out of the domain model. Stack-specific mapping (e.g. EF value
  converters, owned types) lives in the active pack.

# Naming

A name is the cheapest documentation and the most-read part of the code. Good names remove the need
for comments. All names in English.

## Rules

- **Intention-revealing.** The name answers *why it exists, what it does, how it's used*. If a
  comment is needed to explain a name, the name is wrong. `elapsedDays`, not `d`.
- **Honest.** The name must match what the thing actually does. A `getUser` that also creates one is
  a lie; a `validate` that mutates is a trap. Rename or split until the name is true.
- **Pronounceable & searchable.** Avoid invented abbreviations and single letters (except trivial
  loop indices). You can't grep for `genYmdHms`.
- **One word per concept.** Don't mix `fetch`/`get`/`retrieve` for the same idea across the codebase.
  Pick one and keep it.
- **Length matches scope.** Short names for short-lived locals; descriptive names for fields,
  methods, and types whose scope is wide.
- **No type noise.** Avoid Hungarian prefixes and redundant suffixes (`strName`, `userObject`,
  `IUserInterface`). Let the type system carry the type.
- **No disinformation.** Don't call something a `List` if it isn't one; don't use `master`/`slave` or
  other misleading or loaded terms.

## By kind

- **Booleans / predicates:** read as a yes/no question — `isActive`, `hasPermission`, `canRetry`.
- **Functions:** verb or verb-phrase — `calculateTotal`, `parseDate`. Side-effect-free queries read
  as nouns or `get…`.
- **Classes / types:** noun or noun-phrase — `Invoice`, `PaymentGateway`. Not verbs.
- **Collections:** plural — `orders`, not `orderList`.
- **Constants:** name the meaning, not the literal — `MAX_RETRIES = 3`, never the bare `3`.

## Ubiquitous language

Use the domain's real vocabulary, consistently, from the database to the UI. If the business says
"policy," the code says `Policy` — not `Contract`, not `Agreement`. One concept, one name, everywhere.
A mismatch between domain language and code names is itself a smell worth flagging.

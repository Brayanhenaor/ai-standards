# Code smells — detect & remedy

A smell is a surface symptom of a deeper design problem. It's a prompt to look closer, not an
automatic defect. Confirm the underlying problem before refactoring, and never refactor outside the
task's scope — flag it instead.

## Bloaters

| Smell | Detection | Remedy |
|---|---|---|
| **Long method** | Doesn't fit on a screen; needs section comments | Extract sub-functions by responsibility |
| **Large class** | Many fields/methods; low cohesion | Split along responsibility axes (SRP) |
| **Long parameter list** | 4+ params, or several always passed together | Introduce a parameter object / value type |
| **Primitive obsession** | Strings/ints carrying domain meaning (`string currency`, `int status`) | Introduce a value object or enum |
| **Data clumps** | The same group of fields travels together everywhere | Make the group its own type |

## Object-orientation abusers

| Smell | Detection | Remedy |
|---|---|---|
| **Switch on type** | Repeated `switch`/`if` over a type tag | Polymorphism / strategy (Open-Closed) |
| **Refused bequest** | Subclass ignores or throws on inherited members | Replace inheritance with composition |
| **Temporary field** | Field only set in some flows, null otherwise | Extract the flow into its own object |

## Change preventers

| Smell | Detection | Remedy |
|---|---|---|
| **Divergent change** | One class edited for many unrelated reasons | Split by reason-to-change (SRP) |
| **Shotgun surgery** | One change forces edits across many classes | Gather the scattered responsibility into one place |
| **Parallel inheritance** | Adding a subclass here forces one there | Collapse or redirect the hierarchies |

## Couplers

| Smell | Detection | Remedy |
|---|---|---|
| **Feature envy** | A method uses another object's data more than its own | Move the method to where the data lives |
| **Inappropriate intimacy** | Two classes reach into each other's internals | Tighten the interface; extract a mediator |
| **Message chains** | `a.getB().getC().getD()` | Apply Law of Demeter; add a delegating method |
| **Middle man** | A class only forwards calls | Remove it; talk to the real collaborator |

## Dispensables

| Smell | Detection | Remedy |
|---|---|---|
| **Dead code** | Unreachable / unused | Delete it (version control remembers) |
| **Speculative generality** | Abstractions, hooks, params "for the future" | Remove until actually needed (YAGNI) |
| **Comments compensating for bad code** | Comments explaining *what* convoluted code does | Refactor so the code explains itself; keep comments for *why* |
| **Duplicated knowledge** | Same decision/rule in multiple places | Extract — but confirm it's real, not coincidental, duplication |

## Two smells point the *other* way (under-engineering)

Most smells warn against too little structure. These warn against too much — equally real:

- **Speculative generality** — structure for needs that don't exist. The signature of
  over-engineering. Cut it.
- **Indirection without value** — wrappers, layers, and interfaces that only forward. If removing it
  makes the code clearer, remove it.

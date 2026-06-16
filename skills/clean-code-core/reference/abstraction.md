# Abstraction, coupling & duplication

Where the hierarchy is most often tested: the line between "clean separation" and "needless
indirection," and between "real duplication" and "things that merely look alike."

## Levels of abstraction

- Keep each module/function at a consistent level. High-level policy reads like prose and delegates
  detail downward; it doesn't interleave SQL strings with business decisions.
- A jump in abstraction level inside one unit (orchestration suddenly doing byte manipulation) is a
  signal to extract the low-level part.

## Cohesion

- **High cohesion:** everything in a unit works toward one purpose. Methods use most of the class's
  fields; the class has one job.
- **Low cohesion smell:** a class whose methods split into clusters that touch disjoint fields —
  it's two classes wearing one name. Split it.

## Coupling

- **Low coupling:** units interact through small, stable contracts, not each other's internals.
- **Depend on abstractions** at boundaries you need to swap or test; depend directly on stable,
  obvious things elsewhere. Don't abstract a dependency that has no reason to change.
- **Law of Demeter.** Talk to immediate collaborators, not their internals. `a.getB().getC().do()`
  (a train wreck) couples you to a whole object graph — ask the collaborator to do the work instead.
- **Tell, don't ask.** Prefer telling an object to do something over pulling its data out to decide
  for it. Behavior belongs with the data it acts on.

## DRY vs coincidental duplication

DRY is about **knowledge**, not about identical text. Two snippets that look the same but encode
*different* decisions are not duplication — merging them couples things that should evolve apart.

- **Real duplication:** the same business rule or decision expressed in multiple places. Changing the
  rule means editing all of them — and forgetting one causes a bug. Extract it.
- **Coincidental duplication:** code that happens to look alike today but answers to different
  reasons-to-change. Leave it apart.
- **Rule of three.** Two occurrences? Often wait. The third confirms the pattern is real and reveals
  the right abstraction. Extracting on the first sight of similarity is how speculative, wrong
  abstractions are born — and a wrong abstraction is more expensive than the duplication it replaced.

## The abstraction test

Before introducing an interface, base class, generic, or layer, ask:

1. Does it remove **real, present** duplication or a **real, present** need to swap/test?
2. Will it have more than one implementation/user **now** — not hypothetically?
3. Does it make the calling code **easier** to read, or just more indirect?

If the honest answers are no, the abstraction is over-engineering. Inline it and move on.

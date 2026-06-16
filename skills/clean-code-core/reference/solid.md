# SOLID — language-agnostic

SOLID is a means, not a goal. Apply a principle when it removes a real, present problem; skip it when
it only adds indirection. For each: the intent, the smell it prevents, the fix, and when *not* to.

## S — Single Responsibility

**Intent:** a unit (function, class, module) has one reason to change — one actor it answers to.

**Smell:** a class that parses input *and* applies business rules *and* writes to the DB; a change
to any one forces touching the others.

**Fix:** split along the axes of change. Group what changes together; separate what changes for
different reasons.

**Not when:** splitting produces anemic fragments that are always used together and never change
independently. Two things that change for the same reason belong together.

## O — Open/Closed

**Intent:** extend behavior without modifying tested code.

**Smell:** a growing `switch`/`if-else` over a type tag that you edit every time a new case appears.

**Fix:** polymorphism, strategy, or a registry — new behavior arrives as a new implementation, not an
edit to the old one.

**Not when:** there are only two stable cases and none on the horizon. A premature plugin system to
support variants that don't exist is over-engineering. Wait for the third case (rule of three).

## L — Liskov Substitution

**Intent:** a subtype must be usable anywhere its base type is, without surprises.

**Smell:** an override that throws `NotSupported`, tightens preconditions, or returns something
callers don't expect (the classic `Square extends Rectangle` trap).

**Fix:** model the real relationship. Prefer composition over inheritance when "is-a" doesn't hold
for *all* behavior. Honor the base contract or don't inherit.

**Not when:** — this one has no "skip"; a violation is always a design error.

## I — Interface Segregation

**Intent:** no client is forced to depend on methods it doesn't use.

**Smell:** a fat interface where implementers stub half the methods; a consumer that needs one method
but drags in twenty.

**Fix:** split into role-based interfaces named after what the *client* needs (`IReadOnlyStore`,
`IClock`), not after the implementation.

**Not when:** the interface is small and cohesive already. Don't shatter a coherent contract into
one-method slivers for its own sake.

## D — Dependency Inversion

**Intent:** high-level policy shouldn't depend on low-level detail; both depend on an abstraction.

**Smell:** business logic that `new`s a concrete database client, HTTP client, or clock — untestable,
welded to one implementation.

**Fix:** depend on an abstraction (interface/protocol/function type), inject the concrete one at the
edge. This is what makes code testable and swappable.

**Not when:** the dependency is a stable value type or a pure standard-library function with no
seam worth faking. An interface with exactly one implementation that will never have another, and
that you never need to fake in a test, is often just ceremony — weigh it against testability.

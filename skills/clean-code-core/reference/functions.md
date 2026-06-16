# Function & method design

Functions are the unit where clean code is won or lost. The targets below are heuristics, not laws —
a longer function that reads top-to-bottom at one level of abstraction can beat three fragmented ones.

## Do one thing

- A function does one thing, at one level of abstraction, and its name says what completely — no
  "and." If you can extract a meaningfully-named sub-function from it, it was doing more than one
  thing.
- **Single level of abstraction.** Don't mix high-level policy (`chargeCustomer`) with low-level
  detail (string formatting, byte twiddling) in the same body. Each level calls the one below it.
- If a block needs a comment to explain *what* it does, extract it into a function named after that
  comment.

## Size & shape

- **Short.** Most functions fit in a handful of lines; past ~20 they usually hide multiple
  responsibilities. Length is a symptom, not the disease — extract by responsibility, not to hit a
  number.
- **Few parameters.** 0–2 ideal, 3 is a stretch, 4+ is a smell. Group related parameters into a
  value object; a long parameter list often signals a missing concept.
- **No boolean/flag parameters** that switch behavior — that's two functions wearing one name. Split
  them.
- **No output parameters.** Return a value (or a small record) instead of mutating an argument.

## Side effects & purity

- **Command-Query Separation.** A function either *does* something (command, returns void/unit) or
  *answers* something (query, returns a value) — never both. A query that secretly mutates state is
  a trap.
- **No hidden side effects.** A name like `getBalance` must not also open a session or write a log
  that callers depend on. Make effects visible in the name or remove them.
- Prefer pure functions for logic — same input, same output, no I/O. They're trivial to test and
  reason about. Push side effects (I/O, mutation) to the edges.

## Control flow

- **Guard clauses over nesting.** Handle invalid/edge cases early and return; keep the happy path
  flat and last. Deep `if` pyramids are a refactor signal.
- **Fail fast.** Validate inputs at the boundary and reject early with a clear error, rather than
  letting bad data flow inward.
- **No deep nesting.** More than 2–3 levels of indentation usually means a sub-function is hiding
  inside.

## Errors

- Use the language's idiomatic error mechanism; don't invent control flow with exceptions for
  expected outcomes (model those as a result/option type where the language supports it).
- Never swallow errors silently — no empty catch, no returning null to hide a failure. Let it
  propagate or handle it meaningfully.

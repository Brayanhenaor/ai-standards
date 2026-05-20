# Guided refactoring

Produce a safe, step-by-step refactoring plan for a specific area of technical debt. Never refactor and implement a new feature simultaneously. Each step must leave the codebase in a green state (tests passing, build succeeding).

**Usage:**
- `/user:refactor-dotnet [file, class, or method]` — plan a refactor for a specific area
- `/user:refactor-dotnet` — identify the highest-priority debt in the current branch changes

---

## Step 0 — Load context

Read `CLAUDE.md` first. Extract:
- Architecture (which layer is this code in?)
- Test coverage expectations
- Whether the area has existing tests

Then read the target file(s) in full. Run:
```bash
git log --oneline -10 -- [target file]    # recent change history
git diff main...HEAD -- [target file]     # pending changes
```

---

## Step 1 — Smell detection

Identify which code smells are present. Only flag smells that require structural change — not style or naming (those are review-dotnet concerns).

### Method-level smells

**Long Method (> 20 lines of logic):**
```csharp
// Smell: single method doing validation + mapping + persistence + event publishing
public async Task<Result> HandleAsync(CreateOrderCommand cmd)
{
    // 60 lines of mixed responsibilities
}

// Fix: Extract Method
private void ValidateOrder(CreateOrderCommand cmd) { ... }
private Order MapToOrder(CreateOrderCommand cmd) { ... }
private async Task PublishEventAsync(Order order) { ... }
```

**Long Parameter List (> 3 parameters):**
```csharp
// Smell
public Order Create(string name, Guid customerId, decimal amount, string currency, Guid addressId, bool isPriority) { }

// Fix: Introduce Parameter Object
public Order Create(CreateOrderParameters parameters) { }
```

**Nested Conditionals (> 2 levels):**
```csharp
// Smell
if (order != null) {
    if (order.IsActive) {
        if (order.HasItems) {
            // logic
        }
    }
}

// Fix: Guard clauses (early return)
if (order is null) return Result.Failure("OrderNotFound");
if (!order.IsActive) return Result.Failure("OrderInactive");
if (!order.HasItems) return Result.Failure("NoItems");
// logic
```

### Class-level smells

**Anemic Domain Model:**
```csharp
// Smell: entity with no behavior, all logic in service
public class Order { public string Status { get; set; } }  // mutable, no invariants

// Fix: push behavior into entity
public class Order {
    public OrderStatus Status { get; private set; }
    public void Cancel(string reason) {
        if (Status == OrderStatus.Shipped) throw new InvalidOperationException("Cannot cancel shipped order");
        Status = OrderStatus.Cancelled;
    }
}
```

**Primitive Obsession:**
```csharp
// Smell: string/int representing domain concepts
public class Order { public string Status; public decimal Amount; public string Currency; }

// Fix: Value Objects
public record Money(decimal Amount, Currency Currency);
public class Order { public OrderStatus Status; public Money Total; }
```

**God Class (> 500 lines, many responsibilities):**
- Split into multiple classes by Single Responsibility Principle
- Each class: one reason to change

**Feature Envy (method uses another class's data more than its own):**
```csharp
// Smell: OrderService doing things that belong in Order
public decimal CalculateDiscount(Order order) =>
    order.Items.Sum(i => i.Price * i.Quantity) * order.Customer.DiscountRate;

// Fix: Move method to Order or relevant aggregate
public decimal CalculateDiscount() => Items.Sum(...) * Customer.DiscountRate;
```

**Data Clumps (same group of fields always appear together):**
```csharp
// Smell: always passed together
void Ship(string street, string city, string postalCode, string country) { }

// Fix: Value Object
void Ship(Address address) { }
```

**Switch on Type / Status:**
```csharp
// Smell: if/else or switch on type with duplicated logic
if (order.Status == "Pending") ProcessPending();
else if (order.Status == "Active") ProcessActive();

// Fix: Strategy pattern or switch expression + polymorphism
```

---

## Step 2 — Safety check

Before any refactor, verify:

1. **Test coverage exists** — if not, write characterization tests FIRST:
   ```csharp
   // Characterization test: capture current behavior without understanding it
   [Fact]
   public void CalculateTotal_WithMixedItems_ReturnsExpectedValue()
   {
       var result = _service.CalculateTotal(existingOrder);
       Assert.Equal(expectedValue, result);  // lock current behavior
   }
   ```

2. **Build is green** — `dotnet build` must pass before starting

3. **All tests pass** — `dotnet test` must pass before starting

4. **Scope is defined** — identify exactly which classes/methods change

---

## Step 3 — Refactoring plan

Output a numbered, atomic step plan. Each step:
- Has a single, specific change
- Leaves the codebase in a compilable, green state
- References exact file and class names
- Specifies which test to run to verify

### Plan template:

```
## Refactoring plan — [class/method/area]

### Smell detected
[Name of smell, 1-2 lines of why it's a problem]

### Safety check
- [ ] Characterization tests exist: [yes / to be written in Step 1]
- [ ] Build green
- [ ] Tests green

### Steps

Step 1: [Single atomic change]
- File: [path]
- Change: [what to do — Extract Method / Introduce Parameter Object / etc.]
- Verify: dotnet test [TestProject]

Step 2: [Next atomic change — only after Step 1 is green]
- File: [path]
- Change: [what to do]
- Verify: dotnet test [TestProject]

[Continue until refactor complete]

### What does NOT change
- [Public API / interface contracts that callers depend on]
- [Behavior — tests must pass identically before and after]
- [Dependencies registered in DI — interface names stable]

### Estimated effort
[Small / Medium / Large] — [N steps, N files affected]
```

---

## Step 4 — Execution rules

These rules apply when the developer asks to execute the plan (not just plan it):

1. **One step at a time** — implement Step 1, verify build + tests, then Step 2
2. **No feature additions during refactor** — pure structural change only
3. **If tests break** — stop, revert, re-analyze before continuing
4. **If behavior change is needed** — split into: (a) refactor PR, (b) feature PR
5. **Backward compatibility** — public interfaces, method signatures, DI registrations do not change without explicit deprecation path
6. **Commit each step** — `refactor: [description]` conventional commit after each green step

---

## Output rules

- Always produce a numbered plan — never start refactoring without a plan
- If tests are missing, Step 1 is ALWAYS "write characterization tests"
- If the smell is in a public API or interface, flag the backward compatibility constraint explicitly
- If the smell requires domain model changes, cross-reference `/user:domain-dotnet` for aggregate design guidance
- If the smell is performance-related, cross-reference `/user:performance-dotnet` before restructuring
- Estimate effort honestly — "Large refactor" means it should be its own PR, not mixed with features

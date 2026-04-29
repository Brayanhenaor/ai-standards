# Generate complete feature scaffold

Act as a senior .NET developer. Generate a complete, production-ready feature scaffold — all layers, all files — following the project's actual conventions and the standards in CLAUDE.md.

**Usage:**
- `/user:scaffold-dotnet <feature name and brief description>`

Example: `/user:scaffold-dotnet Order cancellation — an order can be cancelled by the customer if it hasn't been shipped yet`

## $ARGUMENTS

---

## Step 1 — Understand the project before generating anything

Read `CLAUDE.md` to understand:
- Architecture (Clean Architecture layers, simple 3-layer, or other)
- Whether CQRS with MediatR is in use
- DTO naming convention (`XRequest`/`XResponse` or other)
- Error handling: `Result<T>`, exceptions, or both
- Mapping: Mapster with `IRegister`, AutoMapper, or manual
- Base response type (`ApiResponse<T>` or plain)
- Test libraries (xUnit, FluentAssertions, NSubstitute assumed unless different)

Then read 1–2 existing features to understand the real patterns in use:
- A representative entity in `Domain/`
- A representative command/query handler or service in `Application/`
- A representative controller in `API/`
- A representative test class

Do not invent patterns — mirror exactly what exists.

---

## Step 2 — Clarify if needed

If `$ARGUMENTS` leaves critical decisions open, ask in one message:
- What are the business rules / invariants? (e.g., "cannot cancel if status is Shipped")
- What should happen to related data? (e.g., refund triggered, inventory restored)
- Is this a new aggregate or part of an existing one?
- Any authorization requirement for this endpoint?

If the description is clear enough, state your assumptions and proceed.

---

## Step 3 — Generate all files

Generate every file needed for the feature. For Clean Architecture with MediatR, that means:

### Domain layer
```
Domain/
  Entities/[Entity].cs                    — if new entity or aggregate
  Events/[FeatureName]Event.cs            — domain event if a business fact occurred
  Exceptions/[FeatureName]Exception.cs    — domain-specific exception if needed
```

### Application layer
```
Application/
  Features/[FeatureName]/
    [FeatureName]Command.cs               — command + handler in same file (if write operation)
    [FeatureName]Query.cs                 — query + handler in same file (if read operation)
    [FeatureName]Request.cs               — input DTO
    [FeatureName]Response.cs              — output DTO
    [FeatureName]Validator.cs             — FluentValidation or DataAnnotations validator
    [FeatureName]MappingConfig.cs         — Mapster IRegister config (if mapping needed)
  Interfaces/
    I[Repository].cs                      — new repository interface if needed
```

### Infrastructure layer
```
Infrastructure/
  Repositories/[Repository].cs           — implementation if new repository
  Persistence/Configurations/[Entity]Configuration.cs  — EF config if new entity
```

### API layer
```
API/
  Controllers/[Resource]Controller.cs    — new endpoint (or add to existing controller)
```

### Tests
```
Tests.Unit/
  Features/[FeatureName]/[FeatureName]HandlerTests.cs   — handler unit tests
  Domain/[Entity]Tests.cs                               — domain logic tests if applicable
```

Adapt structure to the real architecture found in Step 1. If the project does not use CQRS, generate a service + service interface instead of command/query handlers.

---

## Step 4 — Standards checklist (apply to every generated file)

**Domain:**
- [ ] Entity enforces its own invariants in constructor and methods — no anemic model
- [ ] Properties have `private set` or `init` where immutability is required
- [ ] Collections exposed as `IReadOnlyList<T>` with private backing field
- [ ] Guard clauses throw domain exceptions with meaningful messages
- [ ] Domain event raised if a significant business fact occurred

**Application:**
- [ ] Handler is thin: orchestrates, does not contain business logic
- [ ] `CancellationToken` in every async method
- [ ] `Result<T>` or exception for expected error cases — no `null` returns
- [ ] Validation happens before the handler executes (via middleware or explicit check)
- [ ] Read queries use `.AsNoTracking().Select()` projection — never full entity loads

**API:**
- [ ] Controller is thin: receives request, calls application, returns `ApiResponse<T>`
- [ ] `[ProducesResponseType]` for all possible HTTP codes
- [ ] `[Authorize(Policy = "...")]` if endpoint requires authorization
- [ ] Route follows project's convention (PascalCase `/api/Resource/{id}`)

**Tests:**
- [ ] AAA pattern with explicit `// Arrange`, `// Act`, `// Assert` comments
- [ ] `_sut` for System Under Test
- [ ] NSubstitute for all dependencies
- [ ] FluentAssertions for all assertions
- [ ] One scenario per test
- [ ] Covers: happy path, not found, validation failure, business rule violation

---

## Step 5 — Output

For each file, output the complete content with the file path as header:

```
### Domain/Entities/Order.cs
[complete file content]

### Application/Features/CancelOrder/CancelOrderCommand.cs
[complete file content]

...
```

After all files, show a summary:

```
## Scaffold generado — [FeatureName]

| Archivo | Descripción |
|---|---|
| `Domain/Entities/X.cs` | ... |
| `Application/Features/.../XCommand.cs` | ... |
| ... | ... |

Supuestos aplicados:
- [supuesto 1]
- [supuesto 2]

⚠️ Pasos manuales requeridos:
- [ ] Registrar repositorio en DI: `services.AddScoped<IXRepository, XRepository>()`
- [ ] Agregar migración: `dotnet ef migrations add [NombreMigración]`
- [ ] [cualquier otro paso que no se puede generar automáticamente]
```

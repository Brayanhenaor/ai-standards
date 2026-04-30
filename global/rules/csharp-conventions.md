---
paths:
  - "**/*.cs"
---

# C# conventions

## Naming
- `PascalCase`: classes, methods, properties, events, constants
- Constants in static classes grouped by domain (`ErrorCodes`, `PolicyNames`) — never scattered string literals; exception: log messages
- `camelCase`: parameters, local variables, private fields
- `I` prefix: interfaces (`IUserRepository`)
- `Async` suffix: every async method (`GetUserAsync`)

## Style
- Never align assignments, switch arms, or object mappings with extra spaces — single space only
- Records for immutable DTOs and value objects
- Prefer explicit type over `var`; use `var` only when type is obvious from right-hand side
- `switch` expressions over chained `if/else if` for multiple cases
- Use `is null` / `is not null` instead of `== null` / `!= null`
- Enable `<Nullable>enable</Nullable>` in all projects
- Do not suppress nullable warnings with `!` without a comment explaining why it is safe

## Async and cancellation
- Always `async/await` for I/O — never `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`
- `async void` only in event handlers — all other cases use `async Task`
- `CancellationToken` in all async methods that do I/O or call external services
- Never capture `this` in long-lived closures without unsubscribing

## Collections and null
- Prefer `IReadOnlyList<T>` / `IEnumerable<T>` over `List<T>` in public signatures
- Never return `null` from a service to indicate "not found" — use `Result<T>` or throw exception
- Always return empty collection, never `null`

## Performance
- Never `new HttpClient()` — always `IHttpClientFactory` to avoid socket exhaustion
- `IDisposable` / `IAsyncDisposable`: always wrap in `using` / `await using`
- `StringBuilder` in loops — never `string +=` inside iterations
- `IAsyncEnumerable<T>` for streaming large volumes — never `.ToList()` on thousands of records

## Logging
- `ILogger<T>` in all services — never `Console.WriteLine`
- Structured logging with Serilog; always include relevant properties as context
- Levels: `Debug` (internal flow), `Information` (business events), `Warning` (unexpected/recoverable), `Error` (user-impacting + include exception)
- Never log: passwords, tokens, cards, PII, connection strings
- Include `correlationId` in all logs for traceability

## Object mapping (Mapster)
- Mapping configs in `XMappingConfig` implementing `IRegister`, located in `Application/`
- Register automatically at startup: `TypeAdapterConfig.GlobalSettings.Scan(assembly)`
- Inject `IMapper` via DI — never static `TypeAdapter.Adapt<T>()` in services
- Allowed: `Entity → XResponse`, `XRequest → Entity`, `XRequest → Command/Query`
- Never `Entity → Entity` for updates — assign properties explicitly so intent is clear

## DTOs and validation
- `XRequest` (input), `XResponse` (output) — no generic "Dto" suffix
- Validation with DataAnnotations on `XRequest` classes
- Enable automatic model validation — never validate manually in controllers or services

## Guard clauses
Return or throw early for invalid cases — happy path is the main flow, no deep nesting:

```csharp
// BAD
if (user != null) {
    if (user.IsActive) { /* logic */ }
}

// GOOD
if (user is null) throw new NotFoundException();
if (!user.IsActive) throw new BusinessException("User is inactive");
// logic...
```

## Code smells (flag and report, do not fix outside task scope)
- **Long method** (> 20 lines): extract private methods with descriptive names
- **Long parameter list** (> 3): group into parameter object or use Builder
- **Large class** (> 300 lines): likely violates SRP
- **Magic numbers**: any literal not 0 or 1 → named constant
- No `dynamic`, no `object` as return type or parameter
- No generic `catch (Exception)` without re-throw or structured logging
- No business logic in controllers, middleware, or infrastructure
- Never return EF entities directly from the API — always DTOs/records
- No static services with mutable state

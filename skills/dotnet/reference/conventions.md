# C# conventions

On top of the core's naming/function rules — the .NET idioms.

## Naming

- `PascalCase`: types, methods, properties, events, constants. `camelCase`: parameters, locals,
  private fields — **no `_` prefix** (`field`, not `_field`).
- `I` prefix for interfaces (`IUserRepository`). `Async` suffix on every awaitable method.
- Group domain constants in static classes (`ErrorCodes`, `PolicyNames`) — no scattered string
  literals (log message templates excepted).

## Nullable & types

- `<Nullable>enable</Nullable>` in every project. Don't suppress with `!` without a comment justifying
  why it's safe.
- `is null` / `is not null`, never `== null`.
- Prefer `record` for immutable DTOs and value objects.
- `var` only when the type is obvious from the right-hand side; otherwise spell the type.
- `switch` expressions over `if/else if` chains for multi-case logic.

## Async & cancellation

- `async/await` for all I/O. Never `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` — they deadlock
  and block threads.
- `async Task`, never `async void` (except event handlers).
- Accept and honor a `CancellationToken` on every async method that does I/O or calls out; flow it
  all the way down.

## Collections & null returns

- Public signatures return `IReadOnlyList<T>` / `IEnumerable<T>`, not `List<T>`.
- Never return `null` to mean "not found" — return an empty collection, or a `Result<T>`/exception
  for a single item.
- `IAsyncEnumerable<T>` for streaming large sequences — don't `.ToList()` thousands of rows.

## Time — `TimeProvider`

- Inject `TimeProvider` (.NET 8+) instead of calling `DateTime.UtcNow` directly. It makes time
  testable (`FakeTimeProvider` in tests) and removes hidden static dependencies.
- Always UTC at rest and in transit (`GetUtcNow()`); convert to local only at the edge.

## Logging — source-generated

- `ILogger<T>` everywhere; never `Console.WriteLine`. Structured logging — pass values as named
  properties, not string-interpolated.
- Prefer **source-generated logging** for hot paths — it avoids boxing and unnecessary allocation:

```csharp
public static partial class Log
{
    [LoggerMessage(Level = LogLevel.Warning, Message = "User {UserId} not found")]
    public static partial void UserNotFound(ILogger logger, Guid userId);
}
```

- Levels: `Debug` (internal flow), `Information` (business events), `Warning` (recoverable),
  `Error` (user-impacting, include the exception). Never log secrets, tokens, or PII.

## HTTP & disposables

- Never `new HttpClient()` — use `IHttpClientFactory` (typed/named clients) to avoid socket
  exhaustion and pick up resilience handlers.
- Wrap `IDisposable`/`IAsyncDisposable` in `using`/`await using`.
- `StringBuilder` for concatenation in loops, never `string +=`.

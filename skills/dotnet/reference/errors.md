# Error handling

## Result<T> vs exceptions

- **`Result<T>`** for *expected* domain outcomes (business-rule violations, alternative flows). They
  are part of the API, not failures.
- **Exceptions** for *unexpected* failures — programming errors, infrastructure down, broken
  invariants. Never use exceptions for normal control flow.

| Scenario | Pattern |
|---|---|
| Business rule violated (out of stock) | `Result.Failure(...)` |
| Validation failure | `ValidationException` → 400 |
| Not found (expected) | `Result.Failure` or `NotFoundException` → 404 |
| Unauthorized | `ForbiddenException` → 403 |
| DB down / deserialization / unexpected | let it propagate → 500 |

Use the project's existing `Result<T>` if one exists; don't introduce a competing type.

## Exception hierarchy

One base per bounded context; each exception declares its own HTTP status. Never throw raw
`Exception`/`ApplicationException`.

```csharp
public abstract class AppException(string message) : Exception(message)
{
    public abstract int StatusCode { get; }
}

public sealed class NotFoundException(string resource, object id)
    : AppException($"{resource} '{id}' was not found") { public override int StatusCode => 404; }

public sealed class ConflictException(string message)
    : AppException(message) { public override int StatusCode => 409; }
```

## Global handling — `IExceptionHandler` (.NET 8+)

Use the first-party `IExceptionHandler` + `AddProblemDetails()`, not a hand-rolled
`UseExceptionHandler(lambda)`. Never `try/catch` in controllers.

```csharp
internal sealed class AppExceptionHandler(IProblemDetailsService problemDetails)
    : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext ctx, Exception ex, CancellationToken ct)
    {
        var status = ex is AppException app ? app.StatusCode : StatusCodes.Status500InternalServerError;
        ctx.Response.StatusCode = status;
        return await problemDetails.TryWriteAsync(new()
        {
            HttpContext = ctx,
            ProblemDetails =
            {
                Status = status,
                Title = ex is AppException ? ex.GetType().Name : "InternalServerError",
                Detail = status == 500 ? null : ex.Message,   // never leak internals on 500
            }
        });
    }
}

// Program.cs
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<AppExceptionHandler>();
app.UseExceptionHandler();
```

## ProblemDetails (RFC 9457)

All error responses are ProblemDetails (RFC 9457, which obsoletes 7807). Include a correlation id;
never expose stack traces or SQL in production. Validation errors return the `errors` dictionary.

## Logging by exception type

| Type | Level |
|---|---|
| `ValidationException` | not logged (expected) |
| `NotFoundException` / `ConflictException` / `ForbiddenException` | `Warning` |
| Infrastructure / unexpected | `Error` (full exception + correlation id) |

Never swallow: no empty `catch`, no `catch (Exception) { return null; }`. Let it reach the handler.

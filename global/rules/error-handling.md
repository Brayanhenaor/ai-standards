---
paths:
  - "**/*.cs"
alwaysApply: false
description: "Error handling: Result<T>, ProblemDetails, exception hierarchy, logging levels"
---

# Error handling standards

## Result<T> vs exceptions

Use `Result<T>` for **expected** outcomes that are part of the domain flow. Use exceptions for **unexpected** failures that represent programming errors or infrastructure failures.

```csharp
// Expected domain outcome → Result<T>
Result<Order> PlaceOrder(PlaceOrderCommand cmd);
// Returns: Success(order) | Failure("ProductOutOfStock") | Failure("InsufficientFunds")

// Unexpected infrastructure failure → exception
// DB connection drops, deserialization fails, HTTP call returns 500 → throw
```

**Decision rule:**
| Scenario | Pattern |
|----------|---------|
| Business rule violation (product out of stock) | `Result.Failure("...")` |
| Entity not found (expected caller error) | `Result.Failure(...)` or `NotFoundException` |
| Validation failure (bad input) | `ValidationException` → 400 |
| Unauthorized access | `ForbiddenException` → 403 |
| DB connection failure | Let it propagate as infrastructure exception → 500 |
| Deserialization error | Let it propagate → 500 |
| External API timeout | Polly handles retry/circuit breaker, let final failure propagate |

---

## Exception hierarchy

Define a base exception class per bounded context. Never throw raw `Exception` or `ApplicationException`.

```csharp
// Base — declares its own HTTP status code
public abstract class AppException : Exception
{
    public abstract int StatusCode { get; }
    protected AppException(string message) : base(message) { }
}

// Domain exceptions
public class NotFoundException : AppException
{
    public override int StatusCode => 404;
    public NotFoundException(string resource, object id)
        : base($"{resource} with id '{id}' was not found.") { }
}

public class ConflictException : AppException
{
    public override int StatusCode => 409;
    public ConflictException(string message) : base(message) { }
}

public class ForbiddenException : AppException
{
    public override int StatusCode => 403;
    public ForbiddenException(string message) : base(message) { }
}

public class ValidationException : AppException
{
    public override int StatusCode => 400;
    public IReadOnlyDictionary<string, string[]> Errors { get; }
    public ValidationException(IDictionary<string, string[]> errors)
        : base("One or more validation errors occurred.")
    {
        Errors = new Dictionary<string, string[]>(errors);
    }
}
```

---

## Global exception handler

One global handler. Never `try/catch` in controllers.

```csharp
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
        var (status, title, detail) = exception switch
        {
            AppException ex => (ex.StatusCode, ex.GetType().Name, ex.Message),
            _ => (500, "InternalServerError", "An unexpected error occurred.")
        };

        // Log unexpected errors only
        if (status == 500)
            logger.LogError(exception, "Unhandled exception. CorrelationId: {CorrelationId}",
                context.TraceIdentifier);

        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Status = status,
            Title = title,
            Detail = status == 500 ? null : detail,   // never expose internal detail on 500
            Instance = context.Request.Path,
            Extensions = { ["correlationId"] = context.TraceIdentifier }
        });
    });
});
```

---

## ProblemDetails (RFC 7807)

All API error responses use ProblemDetails. Never custom error envelopes unless already established in the project.

```json
// 400 — Validation failure
{
  "type": "https://tools.ietf.org/html/rfc7807",
  "title": "ValidationException",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "instance": "/api/Orders",
  "correlationId": "abc-123",
  "errors": {
    "CustomerId": ["'CustomerId' must not be empty."],
    "Amount": ["'Amount' must be greater than 0."]
  }
}

// 500 — Internal error (never expose stack trace or internal detail)
{
  "title": "InternalServerError",
  "status": 500,
  "instance": "/api/Orders",
  "correlationId": "abc-123"
}
```

---

## No catch-all, no swallowing

```csharp
// BAD — swallows exception, caller gets null, no trace
try { return await _repo.GetAsync(id); }
catch { return null; }

// BAD — generic catch loses exception type information
catch (Exception ex) { _logger.LogError(ex, "Error"); return null; }

// GOOD — let it propagate, global handler takes it
// (no try/catch needed in most service methods)
var entity = await _repo.GetAsync(id);  // if DB is down, it propagates cleanly
```

---

## Logging levels per exception type

| Exception type | Log level | Log detail |
|---------------|-----------|------------|
| `ValidationException` | none (expected) | don't log |
| `NotFoundException` | `Warning` | resource + id only |
| `ConflictException` | `Warning` | conflict description |
| `ForbiddenException` | `Warning` | user + attempted resource |
| `AppException` (other) | `Warning` | message |
| Infrastructure / unexpected | `Error` | full exception + correlationId |

```csharp
// BAD — logs validation errors as errors (noise in production alerts)
catch (ValidationException ex)
    _logger.LogError(ex, "Validation failed");

// GOOD — validation is expected, not logged
// (global handler converts to 400 ProblemDetails automatically)

// GOOD — unexpected failure with correlationId for trace
catch (Exception ex) when (ex is not AppException)
    _logger.LogError(ex, "Unhandled. CorrelationId: {Id}", correlationId);
```

---

## Result<T> implementation pattern

Minimal implementation that compiles without external packages:

```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }

    private Result(T value) { IsSuccess = true; Value = value; }
    private Result(string error) { IsSuccess = false; Error = error; }

    public static Result<T> Success(T value) => new(value);
    public static Result<T> Failure(string error) => new(error);
}
```

Use the established `Result<T>` implementation in the project — do not introduce a new one if one already exists.

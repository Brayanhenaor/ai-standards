---
paths:
  - "**/Program.cs"
  - "**/*Extensions.cs"
  - "**/*ServiceCollectionExtensions.cs"
  - "**/*Client.cs"
  - "**/*HttpClient*.cs"
  - "**/*ApiClient*.cs"
  - "**/*Integration*.cs"
  - "**/*Gateway*.cs"
---

# Resilience standards

Every call to an external service (HTTP, queues, third parties) needs explicit resilience policies.

## Configuration

Use `Microsoft.Extensions.Http.Resilience` (.NET 8+) or Polly. Configure via `IHttpClientFactory` — never per-call:

```csharp
builder.Services.AddHttpClient<IPaymentClient, PaymentClient>(client =>
{
    client.BaseAddress = new Uri(options.BaseUrl);
})
.AddResilienceHandler("payment", pipeline =>
{
    pipeline.AddTimeout(TimeSpan.FromSeconds(10));

    pipeline.AddRetry(new HttpRetryStrategyOptions
    {
        MaxRetryAttempts = 3,
        Delay = TimeSpan.FromMilliseconds(500),
        BackoffType = DelayBackoffType.Exponential,
        ShouldHandle = args => args.Outcome switch
        {
            { Exception: HttpRequestException } => PredicateResult.True(),
            { Result.StatusCode: >= HttpStatusCode.InternalServerError } => PredicateResult.True(),
            _ => PredicateResult.False()
        }
    });

    pipeline.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions
    {
        FailureRatio = 0.5,
        MinimumThroughput = 10,
        SamplingDuration = TimeSpan.FromSeconds(30),
        BreakDuration = TimeSpan.FromSeconds(15)
    });
});
```

## Mandatory policies for every external service

| Policy | Why |
|---|---|
| **Timeout** | A slow service blocks threads indefinitely without one |
| **Retry with exponential backoff** | Handles transient failures (5xx, network); max 3 attempts |
| **Circuit breaker** | Stops hammering a failing service; allows it to recover |

## Rules

- Never retry 4xx responses — they are permanent client errors, retrying doesn't help
- Configure timeout BEFORE retry in the pipeline — timeout applies per attempt
- Document timeout and retry values in the ADR with justification
- Named clients (`AddHttpClient<TClient>`) over typed clients for easier testing
- Register policies on the client registration — never wrap individual calls in try/catch with retry logic

## Recommended values by service type

| Service type | Timeout | Retries | Circuit break after |
|---|---|---|---|
| Internal API | 3s | 2 | 50% failure in 20 req |
| External payment | 10s | 1 | 30% failure in 10 req |
| Email / notification | 5s | 3 | 50% failure in 10 req |
| File storage | 15s | 2 | 40% failure in 10 req |

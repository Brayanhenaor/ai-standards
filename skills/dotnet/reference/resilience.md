# Resilience

Every call to an external dependency (HTTP, broker, third party) needs explicit resilience —
configured once on the client, never hand-rolled per call.

## Use the first-party stack

`Microsoft.Extensions.Http.Resilience` (built on Polly v8) via `IHttpClientFactory`. For most cases
the **standard handler** gives sensible timeout + retry + circuit-breaker in one line:

```csharp
builder.Services
    .AddHttpClient<IPaymentClient, PaymentClient>(c => c.BaseAddress = new(opts.BaseUrl))
    .AddStandardResilienceHandler();
```

Customize only when the defaults don't fit:

```csharp
.AddResilienceHandler("payment", p =>
{
    p.AddTimeout(TimeSpan.FromSeconds(10));               // per attempt
    p.AddRetry(new() { MaxRetryAttempts = 3, BackoffType = DelayBackoffType.Exponential,
        ShouldHandle = args => ValueTask.FromResult(args.Outcome.Result?.IsSuccessStatusCode == false) });
    p.AddCircuitBreaker(new() { FailureRatio = 0.5, MinimumThroughput = 10,
        SamplingDuration = TimeSpan.FromSeconds(30), BreakDuration = TimeSpan.FromSeconds(15) });
});
```

## Mandatory per external dependency

| Policy | Why |
|---|---|
| Timeout | A hung dependency otherwise blocks threads forever |
| Retry (exponential backoff) | Rides out transient 5xx/network blips; cap ~3 |
| Circuit breaker | Stops hammering a down service; lets it recover |

## Rules

- **Never retry 4xx** — they're permanent client errors.
- Timeout goes **before** retry in the pipeline (it applies per attempt).
- Configure on the client registration, never wrap individual calls in `try/catch` + manual retry.
- Document chosen timeout/retry values (and why) — an ADR for anything non-default.

## Rough starting points

Internal API ~3s/2 retries · external payment ~10s/1 · email ~5s/3 · file storage ~15s/2. Tune to
real latency; these are starting points, not law.

---
paths:
  - "**/*Consumer*.cs"
  - "**/*Event*.cs"
  - "**/*Command*.cs"
  - "**/*Publisher*.cs"
  - "**/*Saga*.cs"
  - "**/*StateMachine*.cs"
  - "**/*Outbox*.cs"
alwaysApply: false
description: "Async messaging: naming conventions, idempotency, outbox, schema evolution, correlation IDs"
---

# Messaging standards

## Message naming

```csharp
// Commands — imperative, targeted to one consumer
CreateOrderCommand, CancelOrderCommand, SendEmailCommand

// Events — past tense, broadcast
OrderCreatedEvent, OrderCancelledEvent, PaymentConfirmedEvent
```

Rules:
- Commands: `{Action}{Entity}Command`
- Events: `{Entity}{PastVerb}Event`
- Never: `OrderMessage`, `HandleData`, `ProcessEvent`

## Message contracts

- DTOs only — never domain entities or EF Core types as message contracts
- `Guid` for IDs — never `int` / `long`
- All `DateTime` fields in UTC: `DateTime.UtcNow`
- Include `CorrelationId` on events crossing service boundaries
- All fields serializable without special converters

## Schema evolution (breaking changes)

```csharp
// NEVER remove or rename fields — breaks live consumers without redeployment
// GOOD — add optional fields with defaults
public record OrderCreatedEvent(
    Guid OrderId,
    Guid CustomerId,
    string? CustomerEmail = null);    // new optional field — backward compatible
```

For breaking changes: version the type (`OrderCreatedEventV2`), run dual consumers.

## Idempotency — mandatory

Every consumer MUST handle duplicate delivery. MassTransit delivers at-least-once.

```csharp
public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
{
    // Check idempotency key before processing
    if (await _repo.IsAlreadyProcessedAsync(context.Message.OrderId))
        return;

    await _service.ProcessAsync(context.Message);
}
```

Idempotency key: use `context.MessageId` or a business key stored in a `ProcessedMessages` table.

## Outbox pattern — required for DB + message atomicity

When a DB change and message publication must be atomic:

```csharp
// BAD — not atomic: DB saved, crash before publish = lost event
await _context.SaveChangesAsync();
await _bus.Publish(new OrderCreatedEvent(...));  // crash here loses the event

// GOOD — MassTransit EF Outbox (same transaction as DB change)
// Configure: cfg.UseEntityFrameworkOutbox<AppDbContext>(ctx)
// Then just SaveChangesAsync — outbox dispatcher publishes after commit
await _context.SaveChangesAsync();
```

Use `UseInMemoryOutbox` only in tests. Production always uses `UseEntityFrameworkOutbox`.

## Consumer exception handling

```csharp
catch (NotFoundException)
{
    // Non-retriable — do not throw, log warning, skip message
    _logger.LogWarning("Resource not found — skipping");
    return;
}
catch (HttpRequestException)
{
    // Retriable — let MassTransit retry with backoff
    throw;
}
```

Classify every exception type as retriable or non-retriable. Never let all exceptions go to dead-letter by default without classification.

## Correlation IDs

Set on publish, extract in consumer, propagate to all log entries:

```csharp
// Producer
await _bus.Publish(new OrderCreatedEvent(...), ctx =>
    ctx.CorrelationId = correlationId);

// Consumer
_logger.LogInformation("Processing CorrelationId={Id}", context.CorrelationId);
```

## Metrics per consumer

Every consumer must have:
- `{service}_{message_type}_received_total` — counter with `status` tag (success/error)
- `{service}_{message_type}_processing_seconds` — histogram

## Retry and dead-letter configuration

```csharp
e.UseMessageRetry(r => r.Exponential(5,
    TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(2)));

e.UseDelayedRedelivery(r => r.Intervals(
    TimeSpan.FromMinutes(5), TimeSpan.FromMinutes(15), TimeSpan.FromMinutes(60)));
```

Always configure dead-letter queue. Never let failed messages disappear silently.

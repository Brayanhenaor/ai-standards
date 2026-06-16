# Messaging

Async messaging guidance (examples use MassTransit, the common .NET choice — the principles hold for
any broker/library; the specific library is a project decision).

## Naming & contracts

- Commands (imperative, one consumer): `CreateOrderCommand`, `CancelOrderCommand`.
- Events (past tense, broadcast): `OrderCreatedEvent`, `PaymentConfirmedEvent`.
- Never `OrderMessage`/`ProcessEvent`. Contracts are DTOs (never entities/EF types), `Guid` ids,
  UTC `DateTime`, a `CorrelationId` on cross-service events, all fields serializable plainly.

## Idempotency — mandatory

Delivery is at-least-once; every consumer must tolerate duplicates.

```csharp
public async Task Consume(ConsumeContext<OrderCreatedEvent> ctx)
{
    if (await _processed.IsHandledAsync(ctx.MessageId!.Value)) return;
    await _service.HandleAsync(ctx.Message);
    await _processed.MarkAsync(ctx.MessageId.Value);
}
```

Key off `MessageId` or a business key in a `ProcessedMessages` table.

## Outbox — for DB + publish atomicity

When a DB change and a publish must be atomic, use the transactional outbox so a crash between them
can't lose the event. With MassTransit, `UseEntityFrameworkOutbox` — then a single `SaveChangesAsync`
both persists and queues; the dispatcher publishes after commit. `UseInMemoryOutbox` is for tests
only.

## Schema evolution

Never remove/rename fields on a live contract — add optional fields with defaults. For breaking
changes, version the type (`OrderCreatedEventV2`) and run dual consumers during rollout.

## Failure handling

Classify each exception: non-retriable (e.g. not-found) → log and skip, don't throw; retriable
(transient, 5xx) → throw and let retry handle it.

```csharp
e.UseMessageRetry(r => r.Exponential(5, TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(2)));
```

Always configure a dead-letter queue — failed messages must never vanish silently. Emit per-consumer
received/duration metrics and propagate the correlation id to every log line.

# Messaging patterns expert

Review or design asynchronous messaging for the current feature. Apply the lens of an integration architect specializing in MassTransit, RabbitMQ, and Azure Service Bus on .NET. Covers: message design, consumer correctness, idempotency, outbox pattern, saga coordination, error handling, and observability.

**Usage:**
- `/user:messaging-dotnet` — review messaging code in current branch
- `/user:messaging-dotnet [feature description]` — design messaging for a new feature
- `/user:messaging-dotnet [ConsumerClass or MessageType]` — audit a specific consumer or message

---

## Step 0 — Load context

Read `CLAUDE.md` first. Extract:
- Messaging infrastructure (MassTransit + RabbitMQ / Azure Service Bus / AmazonSQS)
- Bus registration pattern (`AddMassTransit`, endpoint naming)
- Existing consumer conventions
- Outbox configuration (`UseEntityFrameworkOutbox`, `UseInMemoryOutbox`)

Then examine changed files:
```bash
git diff main...HEAD --stat
git diff main...HEAD -- "**/*Consumer*.cs" "**/*Event*.cs" "**/*Command*.cs" "**/*Message*.cs" "**/*Publisher*.cs" "**/*Saga*.cs"
```

---

## Step 1 — Message design

### Naming conventions

```csharp
// Commands — imperative, present tense, targeted to one consumer
public record CreateOrderCommand(Guid OrderId, Guid CustomerId, decimal Amount);
public record CancelOrderCommand(Guid OrderId, string Reason);

// Events — past tense, broadcast to any interested consumer
public record OrderCreatedEvent(Guid OrderId, Guid CustomerId, DateTime CreatedAt);
public record OrderCancelledEvent(Guid OrderId, string Reason, DateTime CancelledAt);
```

**Naming rules:**
- Commands: `{Action}{Entity}Command` — verb first, entity second
- Events: `{Entity}{PastVerb}Event` — entity first, past tense verb
- Never: `OrderMessage`, `ProcessEvent`, `HandleCommand` — too generic
- Namespace: `{Project}.Messaging.{Domain}` — discoverable by topic

### Message contract design

- **Never** use domain entities or EF Core types as message contracts — they carry EF navigation properties and change tracking state
- DTOs only: serializable, no behavior, no EF dependencies
- `Guid` for IDs — never `int` or `long` (not unique across distributed systems)
- `DateTime` in UTC (`DateTime.UtcNow`) — never local time
- Include `CorrelationId` on events that cross service boundaries

```csharp
// BAD — entity as message (EF types, navigation properties)
public record OrderCreatedEvent(Order Order);

// GOOD — clean DTO
public record OrderCreatedEvent(
    Guid OrderId,
    Guid CustomerId,
    decimal TotalAmount,
    DateTime CreatedAtUtc,
    Guid CorrelationId);
```

### Schema evolution

- **Never remove fields** from published message contracts — consumers may still rely on them
- **Never rename fields** — breaks deserialization on live consumers
- Add new optional fields with defaults: `string? NewField = null`
- For breaking changes: version the message type (`OrderCreatedEventV2`) and run both consumers during transition

---

## Step 2 — Consumer correctness

### Idempotency (mandatory)

Every consumer MUST handle duplicate delivery. MassTransit delivers at-least-once.

```csharp
public class OrderCreatedConsumer : IConsumer<OrderCreatedEvent>
{
    public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
    {
        var msg = context.Message;

        // Check if already processed — idempotency key
        if (await _repo.ExistsAsync(msg.OrderId, context.CancellationToken))
            return; // already handled, ack silently

        await _service.CreateAsync(msg.OrderId, ...);
    }
}
```

Idempotency key strategy:
- Use `MessageId` (`context.MessageId`) if the producer always sends unique IDs
- Use a business key (`OrderId`, `EventId`) stored in a processed-messages table
- Never rely on deduplication at the broker level as the only safeguard

### Exception handling in consumers

```csharp
// BAD — unhandled exception sends to dead-letter automatically
// but loses context of what state the consumer was in

// GOOD — distinguish retriable from non-retriable
public async Task Consume(ConsumeContext<OrderCreatedEvent> context)
{
    try
    {
        await _service.ProcessAsync(context.Message);
    }
    catch (NotFoundException ex)
    {
        // Non-retriable: data issue — skip (or move to error queue manually)
        _logger.LogWarning(ex, "Order {OrderId} not found — skipping", context.Message.OrderId);
        // Do NOT throw — throwing sends to dead-letter after retries exhausted
    }
    catch (HttpRequestException)
    {
        // Retriable: external call failed — let MassTransit retry
        throw;
    }
}
```

### Consumer registration

```csharp
services.AddMassTransit(x =>
{
    x.AddConsumer<OrderCreatedConsumer>();
    x.AddConsumer<OrderCancelledConsumer>();

    x.UsingRabbitMq((ctx, cfg) =>
    {
        cfg.Host(connectionString);

        cfg.ReceiveEndpoint("order-created-queue", e =>
        {
            e.ConfigureConsumer<OrderCreatedConsumer>(ctx);

            // Retry policy — exponential backoff
            e.UseMessageRetry(r => r.Exponential(5,
                TimeSpan.FromSeconds(1),
                TimeSpan.FromSeconds(30),
                TimeSpan.FromSeconds(2)));

            // Dead-letter on failure
            e.UseDelayedRedelivery(r => r.Intervals(
                TimeSpan.FromMinutes(5),
                TimeSpan.FromMinutes(15),
                TimeSpan.FromMinutes(60)));
        });
    });
});
```

---

## Step 3 — Outbox pattern

**When required:** Any time a DB change and a message publication must happen atomically. Without outbox, a crash between `SaveChanges` and `Publish` causes either a lost message or a duplicate.

```csharp
// BAD — not atomic: DB saved but publish could fail
await _context.SaveChangesAsync();
await _bus.Publish(new OrderCreatedEvent(...));  // crash here = lost event

// GOOD — MassTransit Entity Framework Outbox
// (requires UseEntityFrameworkOutbox configuration)
await _context.SaveChangesAsync();  // outbox message written in same transaction
// bus.Publish is NOT called — MassTransit outbox dispatcher publishes after commit
```

**Setup:**
```csharp
x.UsingRabbitMq((ctx, cfg) =>
{
    cfg.UseEntityFrameworkOutbox<AppDbContext>(ctx);
    cfg.ConfigureEndpoints(ctx);
});
```

**Detect violation:** any consumer or service that calls `SaveChangesAsync()` AND `bus.Publish()` / `bus.Send()` without outbox configured → 🔴 atomicity risk.

---

## Step 4 — Saga coordination

### State machine design

```csharp
public class OrderStateMachine : MassTransitStateMachine<OrderSaga>
{
    public State Pending { get; private set; } = null!;
    public State Confirmed { get; private set; } = null!;
    public State Cancelled { get; private set; } = null!;

    public OrderStateMachine()
    {
        InstanceState(x => x.CurrentState);

        Initially(
            When(OrderCreated)
                .Then(ctx => ctx.Saga.CreatedAt = DateTime.UtcNow)
                .TransitionTo(Pending));

        During(Pending,
            When(PaymentConfirmed)
                .TransitionTo(Confirmed)
                .Publish(ctx => new OrderConfirmedEvent(ctx.Saga.OrderId)),
            When(PaymentFailed)
                .Then(ctx => ctx.Saga.FailureReason = ctx.Message.Reason)
                .TransitionTo(Cancelled)
                .Publish(ctx => new OrderCancelledEvent(ctx.Saga.OrderId)));
    }
}
```

**Saga review checklist:**
- Saga state stored in DB (not in-memory) — survives restarts
- Compensation logic for each failure path (what to undo when something fails)
- Timeout events for stuck sagas (`Schedule`)
- Idempotent transitions — processing same event twice must not corrupt state
- No business logic inside saga — publish events, let consumers handle logic

---

## Step 5 — Observability

### Correlation IDs

```csharp
// Producer — set correlation
await _bus.Publish(new OrderCreatedEvent(...), ctx =>
{
    ctx.CorrelationId = correlationId;
    ctx.Headers.Set("x-correlation-id", correlationId.ToString());
});

// Consumer — extract and propagate to logs
_logger.LogInformation("Processing {MessageType} CorrelationId={CorrelationId}",
    nameof(OrderCreatedEvent), context.CorrelationId);
```

### Required metrics per consumer

```csharp
private static readonly Counter<long> MessagesReceived =
    Metrics.CreateCounter<long>("orders_messages_received_total",
        description: "Messages received by consumer",
        tags: new[] { "message_type", "status" });

private static readonly Histogram<double> ProcessingDuration =
    Metrics.CreateHistogram<double>("orders_message_processing_seconds",
        description: "Consumer processing time",
        tags: new[] { "message_type" });

// Usage
using var _ = ProcessingDuration.Measure("OrderCreatedEvent");
try
{
    await ProcessAsync(message);
    MessagesReceived.Add(1, "OrderCreatedEvent", "success");
}
catch
{
    MessagesReceived.Add(1, "OrderCreatedEvent", "error");
    throw;
}
```

**Every consumer must have:** received counter (success + error), processing duration histogram.

---

## Step 6 — Testing

### Unit test consumers

```csharp
[Fact]
public async Task Consume_WhenOrderExists_SkipsProcessing()
{
    // Arrange
    var harness = new InMemoryTestHarness();
    var consumer = harness.Consumer<OrderCreatedConsumer>();
    await harness.Start();

    _repo.ExistsAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
         .Returns(true); // already processed

    // Act
    await harness.Bus.Publish(new OrderCreatedEvent(Guid.NewGuid(), ...));
    await harness.Consumed.Any<OrderCreatedEvent>();

    // Assert
    await _service.DidNotReceive().CreateAsync(Arg.Any<Guid>(), ...);
    await harness.Stop();
}
```

### Integration test with TestContainers

```csharp
// Use real RabbitMQ with TestContainers — no in-memory for integration tests
var container = new RabbitMqBuilder().Build();
await container.StartAsync();
// configure MassTransit with container.GetConnectionString()
```

---

## Step 7 — Output format

### For review mode:

```
## Revisión de messaging — [branch]

### 🔴 Bloqueantes
- **[archivo:línea]** — descripción
  - *Riesgo:* qué falla en producción
  - *Fix:* corrección concreta con código

### 🟡 Mejoras
- **[archivo:línea]** — descripción
  - *Fix:* corrección

### 🔵 Sugerencias
- **[archivo:línea]** — descripción

### ✅ Revisado sin hallazgos
- [lista de dimensiones limpias]
```

### For design mode:

```
## Diseño de messaging — [feature]

### Mensajes propuestos
[Definición de contratos con namespace y campos]

### Flujo
[Diagrama o descripción paso a paso: producer → broker → consumer → outbox]

### Configuración del bus
[Código de registro de consumers y endpoints]

### Outbox
[Confirmación de si se necesita y configuración]

### Saga
[Si aplica: state machine con estados y transiciones]

### Idempotencia
[Estrategia de deduplicación]

### Métricas requeridas
[Lista de counters e histogramas a implementar]
```

---

## Output rules

- Every 🔴 finding includes the exact race condition or data loss scenario
- Outbox violations always 🔴 — atomicity is non-negotiable
- Idempotency violations always 🔴 — at-least-once delivery is guaranteed
- Non-retriable vs retriable exceptions must be explicit in every consumer
- Schema evolution violations always flagged — breaking contracts breaks distributed systems silently

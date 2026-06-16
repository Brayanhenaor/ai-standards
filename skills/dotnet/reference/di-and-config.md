# Dependency injection & configuration

The core's Dependency Inversion principle, made concrete for the .NET container.

## Inject abstractions

- Constructor parameters are interfaces, not concrete classes. Register against the interface:
  `services.AddScoped<IOrderService, OrderService>()`.
- If no interface exists and the dependency needs a seam (to swap or to fake in tests), create one.
  Don't add an interface that has one implementation, will never have another, and is never faked —
  that's ceremony (see core `anti-overengineering`).
- Framework types without an interface (`ILogger<T>`, `IOptions<T>`, `TimeProvider`) inject directly.

## Lifetimes

| Lifetime | Use for |
|---|---|
| `Singleton` | Stateless or thread-safe, expensive to build (`IHttpClientFactory`, caches, config) |
| `Scoped` | One per request — `DbContext`, repositories, business services |
| `Transient` | Lightweight, stateless, cheap |

**Captive-dependency rules (cause concurrency bugs under load):**

- Never inject `Scoped` into `Singleton`. Never inject `DbContext` into a `Singleton`.
- If a `Singleton` truly needs a `Scoped` service, inject `IServiceScopeFactory` and create a scope
  per unit of work.
- A `Transient` `IDisposable` captured by a `Singleton` is never disposed — avoid.

## Keyed services (.NET 8+)

When several implementations of one interface coexist, prefer keyed registration over marker
interfaces or a hand-rolled factory:

```csharp
services.AddKeyedScoped<INotifier, EmailNotifier>("email");
services.AddKeyedScoped<INotifier, SmsNotifier>("sms");

public class Sender([FromKeyedServices("email")] INotifier notifier);
```

## Options pattern

- Read configuration via `IOptions<T>` / `IOptionsSnapshot<T>` / `IOptionsMonitor<T>`. Don't inject
  `IConfiguration` outside the composition root.
- One strongly-typed options class per section (`JwtOptions`, `SmtpOptions`), validated at startup:

```csharp
services.AddOptions<JwtOptions>()
    .Bind(config.GetSection("Jwt"))
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

Keep registration code organized in focused extension methods (`AddPersistence`, `AddMessaging`),
not one giant `Program.cs`.

---
paths:
  - "**/Program.cs"
  - "**/*Extensions.cs"
  - "**/*Registration*.cs"
  - "**/*Module*.cs"
  - "**/*ServiceCollection*.cs"
  - "**/*DependencyInjection*.cs"
---

# Dependency injection — Dependency Inversion Principle

- **Always inject abstractions (interfaces), never concrete implementations**
- Constructor parameters must be interface types, not classes
- Register concrete classes against their interface: `services.AddScoped<IMyService, MyService>()`

```csharp
// BAD
public class OrderService(PaymentProcessor processor) { }

// GOOD
public class OrderService(IPaymentProcessor processor) { }
```

- Exception: framework types with no interface (e.g. `ILogger<T>`, `IOptions<T>`) are acceptable
- If no interface exists, create one before injecting — do not bypass the rule

# Dependency injection lifetimes

| Lifetime | When to use |
|---|---|
| `Singleton` | No mutable state, thread-safe, expensive to create (`IHttpClientFactory`, caches, configuration) |
| `Scoped` | One instance per HTTP request (`DbContext`, repositories, business services) |
| `Transient` | Lightweight, stateless, cheap to create |

**Critical rules:**
- Never inject `Scoped` into `Singleton` — captive dependency, causes concurrency bugs under load
- Never inject `DbContext` into `Singleton` — use `IServiceScopeFactory` to create an explicit scope
- `IDisposable` as `Transient` inside `Singleton` is never released — avoid
- If a `Singleton` needs a `Scoped` service: inject `IServiceScopeFactory`, create scope manually

# Options pattern (configuration)
- Read config in services via `IOptions<T>`, `IOptionsSnapshot<T>`, or `IOptionsMonitor<T>` — never inject `IConfiguration` outside `Host/`
- One options class per section (`SmtpOptions`, `JwtOptions`) with `.ValidateDataAnnotations().ValidateOnStart()`

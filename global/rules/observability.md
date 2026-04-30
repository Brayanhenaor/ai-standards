---
paths:
  - "**/*Metrics*.cs"
  - "**/*Prometheus*.cs"
  - "**/*Telemetry*.cs"
  - "**/*Instrumentation*.cs"
  - "**/*Observer*.cs"
  - "**/*Monitor*.cs"
---

# Prometheus metrics

## Metrics usage pattern — canonical approach

One `*Metrics` class per service/domain. Internal metric objects are `private static readonly` (prometheus-net throws if the same metric name is registered twice — fields must be type-level, not instance-level). The class is injected via interface as `Singleton`.

```csharp
// IOrderMetrics.cs
public interface IOrderMetrics
{
    void RecordRequest(string status);
    IDisposable MeasureLatency();
    void SetQueueDepth(double value);
}

// OrderMetrics.cs
public sealed class OrderMetrics : IOrderMetrics
{
    private static readonly Counter requestCounter = Metrics.CreateCounter(
        "orders_requests_total",
        "Total processed order requests",
        new CounterConfiguration { LabelNames = ["status"] });

    private static readonly Histogram latencyHistogram = Metrics.CreateHistogram(
        "orders_request_duration_seconds",
        "Order processing duration",
        new HistogramConfiguration
        {
            Buckets = Histogram.ExponentialBuckets(0.005, 2, 10)
        });

    private static readonly Gauge queueDepth = Metrics.CreateGauge(
        "orders_queue_depth",
        "Current number of orders pending processing");

    public void RecordRequest(string status) => requestCounter.WithLabels(status).Inc();
    public IDisposable MeasureLatency() => latencyHistogram.NewTimer();
    public void SetQueueDepth(double value) => queueDepth.Set(value);
}
```

**Registration (always Singleton):**
```csharp
services.AddSingleton<IOrderMetrics, OrderMetrics>();
```

**Usage in service:**
```csharp
public class OrderService(IOrderMetrics metrics)
{
    public async Task<Order> ProcessAsync(OrderRequest request)
    {
        using (metrics.MeasureLatency())
        {
            var result = await DoProcessAsync(request);
            metrics.RecordRequest(result.IsSuccess ? "success" : "error");
            return result;
        }
    }
}
```

**Why this pattern:**
- `private static readonly` fields: prometheus-net singleton requirement — duplicate registration throws
- Interface injection: follows DIP, mockable in tests
- Methods typed per metric: no leaking of prometheus-net types into callers
- `using (MeasureLatency())`: exception-safe, records duration even on throw

## Timing measurements
- **Always `using (metrics.MeasureXxx())` — never `Stopwatch` for Prometheus timing**
- `NewTimer()` records duration on `Dispose`, including on exception paths

```csharp
// BAD — misses duration on exception, violates DIP (direct prometheus-net in service)
var sw = Stopwatch.StartNew();
DoWork();
_histogram.Observe(sw.Elapsed.TotalSeconds);

// GOOD
using (metrics.MeasureLatency())
{
    DoWork();
}
```

## What NOT to do

```csharp
// BAD — static access breaks DIP and testability
public class OrderService
{
    public void Process() => OrderMetrics.RequestCounter.Inc();
}

// BAD — per-request metric creation (throws on second call)
public class OrderService
{
    public void Process()
    {
        var counter = Metrics.CreateCounter("orders_total", "");
        counter.Inc();
    }
}

// BAD — delegate wrapper obscures flow and complicates label assignment mid-operation
await metrics.MeasureAsync("process", async () => { ... });
```

## General rules
- One `*Metrics` class per service/domain — not one global `AppMetrics`
- Metric objects: `private static readonly` inside the metrics class
- Inject metrics class as `Singleton` via interface
- Label names: lowercase, snake_case (`status_code`, `http_method`)
- Histogram buckets: always explicit and domain-appropriate — never default for latency
- Gauge = current state; Counter = cumulative events (never decrement a Counter, use Gauge)

## Prometheus — Swarm vs local discovery

**Local (static_configs):**
```yaml
scrape_configs:
  - job_name: 'myservice_api'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['myserviceapi:8080']
        labels:
          service: 'myservice-api'
```

**UAT/PRD on Swarm (dns_sd_configs):**
```yaml
scrape_configs:
  - job_name: 'myservice_api'
    metrics_path: '/metrics'
    dns_sd_configs:
      - names: ['tasks.myservice-uat_myserviceapi']
        type: 'A'
        port: 8080
```

- Swarm DNS pattern: `tasks.{stack-name}_{service-name}`
- Stack name = `{project}-{env}` (e.g. `myservice-uat`, `myservice-prd`)
- One prometheus config per environment: `prometheus.swarm.uat.yml`, `prometheus.swarm.prd.yml`
- Local uses hostname from compose service name; Swarm uses DNS SD so all replicas are scraped

**Prometheus Swarm deploy (stop-first):**
```yaml
deploy:
  update_config:
    order: stop-first
  resources:
    limits:
      memory: 1024M
      cpus: '0.5'
    reservations:
      memory: 256M
      cpus: '0.1'
```

## ILogger + metrics separation
- Metrics measure (counts, durations, gauges) — never replace structured logging
- Do not log inside metric callbacks

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

## Timing measurements
- **Always use `using (X.NewTimer())` — never `Stopwatch` directly for Prometheus histograms/summaries**
- `NewTimer()` records duration automatically on dispose, even on exceptions

```csharp
// BAD
var sw = Stopwatch.StartNew();
DoWork();
_histogram.Observe(sw.Elapsed.TotalSeconds);

// GOOD
using (_histogram.NewTimer())
{
    DoWork();
}
```

## General rules
- Declare metrics as `static readonly` fields on the class that owns them
- Use `Counter`, `Gauge`, `Histogram`, `Summary` from `prometheus-net` — no custom wrappers
- Label names: lowercase, snake_case (e.g. `status_code`, `http_method`)
- Do not create metrics inside loops or per-request constructors — metrics are singletons
- Histogram buckets must be explicit and domain-appropriate — do not rely on defaults for latency

## ILogger + metrics separation
- Metrics measure (counts, durations, gauges) — never replace structured logging
- Do not log inside metric callbacks

# Observability

Default to the **vendor-neutral, first-party** stack: `System.Diagnostics.Metrics` for metrics,
`ActivitySource` for tracing, and **OpenTelemetry** to export. This decouples the code from any one
backend (Prometheus, OTLP, Application Insights…) — the exporter is a configuration choice, not a
code dependency.

> A specific backend (e.g. prometheus-net + a Prometheus/Grafana/Swarm setup) is a **company-profile**
> choice, not a property of clean .NET. Keep backend specifics in the profile/overlay; keep the code
> instrumented against the abstractions below.

## Metrics — `IMeterFactory` + `Meter`

One meter per service/domain, resolved from `IMeterFactory` (DI-friendly, testable). Instruments are
created once and reused.

```csharp
public sealed class OrderMetrics
{
    private readonly Counter<long> _processed;
    private readonly Histogram<double> _duration;

    public OrderMetrics(IMeterFactory factory)
    {
        var meter = factory.Create("MyApp.Orders");
        _processed = meter.CreateCounter<long>("orders.processed", unit: "{order}");
        _duration  = meter.CreateHistogram<double>("orders.duration", unit: "s");
    }

    public void Processed(string status) => _processed.Add(1, new KeyValuePair<string, object?>("status", status));
    public IDisposable Measure() => /* Stopwatch-backed timer that records on Dispose */;
}
```

Register as `Singleton` and inject via its type/interface. Instrument names: lowercase,
dot-namespaced; tag names lowercase. Choose explicit histogram buckets for latency.

## Tracing — `ActivitySource`

```csharp
private static readonly ActivitySource Source = new("MyApp.Orders");

using var activity = Source.StartActivity("ProcessOrder");
activity?.SetTag("order.id", id);
```

Let OpenTelemetry auto-instrument ASP.NET Core, `HttpClient`, and EF Core; add custom spans only
around meaningful business operations. Propagate context across service and message boundaries.

## Wiring OpenTelemetry

```csharp
builder.Services.AddOpenTelemetry()
    .WithMetrics(m => m.AddMeter("MyApp.Orders").AddAspNetCoreInstrumentation().AddHttpClientInstrumentation())
    .WithTracing(t => t.AddSource("MyApp.Orders").AddAspNetCoreInstrumentation().AddEntityFrameworkCoreInstrumentation())
    .UseOtlpExporter();   // or the profile's chosen exporter
```

## Logs vs metrics vs traces

- **Metrics** count and measure (counters, histograms, gauges) — never a substitute for logging.
- **Logs** carry structured detail and correlation ids. Don't log inside metric callbacks.
- **Traces** show causality across calls. Correlate all three with the same ids.

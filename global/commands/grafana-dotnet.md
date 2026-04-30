# Generate Grafana dashboard JSON from project metrics

Scan the project's Prometheus metrics and generate a complete, production-ready Grafana dashboard JSON.

**Usage:**
- `/user:grafana-dotnet` — generate dashboard for the current project
- `/user:grafana-dotnet <service-name>` — scope to a specific service

## $ARGUMENTS

---

## Step 1 — Discover all metrics in the project

Search for metric definitions across the codebase:

```
*Metrics*.cs
*Instrumentation*.cs
*Telemetry*.cs
*Monitor*.cs
```

For each file found, extract:
- **Metric name** (first argument to `Counter.Build()`, `Gauge.Build()`, `Histogram.Build()`, `Summary.Build()`, or the string passed to `Metrics.CreateCounter(...)`, etc.)
- **Metric type**: Counter, Gauge, Histogram, Summary
- **Labels**: any `.LabelNames(...)` or label array
- **Help text**: `.Help(...)` description
- **Where it's incremented/observed**: find all `.Inc()`, `.Set()`, `.Observe()`, `.NewTimer()` call sites to understand what business event each metric tracks

Also check `prometheus.yml` / `prometheus.swarm.*.yml` for `job_name` values — use them as the `job` label in queries.

---

## Step 2 — Map metrics to panel types

Apply this mapping:

| Metric type | Recommended panels |
|---|---|
| Counter | Rate graph (`rate(metric[1m])`), total stat panel |
| Counter with labels | Rate graph per label (`sum by (label) (rate(...))`) |
| Histogram | Latency percentile graph (p50/p90/p99), heatmap |
| Summary | Quantile graph (0.5, 0.9, 0.99) |
| Gauge | Current value stat panel, time series graph |

For Histograms always generate three queries: p50, p90, p99:
```promql
histogram_quantile(0.50, sum(rate(metric_bucket[5m])) by (le))
histogram_quantile(0.90, sum(rate(metric_bucket[5m])) by (le))
histogram_quantile(0.99, sum(rate(metric_bucket[5m])) by (le))
```

For Counters, always show rate not cumulative:
```promql
sum(rate(metric_total[1m]))
```

For labeled Counters, break down by label:
```promql
sum by (label_name) (rate(metric_total[1m]))
```

---

## Step 3 — Organize panels into rows

Group panels by concern:

1. **Overview** — key health stats: request rate, error rate, active connections (stat panels at top)
2. **Latency** — all Histogram/Summary panels (time series + p50/p90/p99)
3. **Throughput** — Counter rates by operation/endpoint
4. **Errors** — error counters, failure rates, DLQ sizes
5. **Resources** — Gauges (queue depth, connection pool, cache size, thread count)
6. **Business metrics** — domain-specific counters (documents processed, emails sent, etc.)

---

## Step 4 — Generate the dashboard JSON

Output a complete Grafana dashboard JSON with:

```json
{
  "__inputs": [],
  "__requires": [],
  "annotations": { "list": [] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "panels": [ /* all panels */ ],
  "refresh": "30s",
  "schemaVersion": 38,
  "tags": ["dotnet", "prometheus", "{project-name}"],
  "templating": {
    "list": [
      {
        "current": {},
        "datasource": { "type": "prometheus", "uid": "${datasource}" },
        "definition": "label_values(up, job)",
        "hide": 0,
        "includeAll": false,
        "label": "Job",
        "name": "job",
        "options": [],
        "query": { "query": "label_values(up, job)", "refId": "StandardVariableQuery" },
        "refresh": 2,
        "type": "query"
      },
      {
        "current": { "selected": false, "text": "All", "value": "$__all" },
        "datasource": { "type": "prometheus", "uid": "${datasource}" },
        "definition": "label_values({job=\"$job\"}, instance)",
        "hide": 0,
        "includeAll": true,
        "label": "Instance",
        "name": "instance",
        "options": [],
        "query": { "query": "label_values({job=\"$job\"}, instance)", "refId": "StandardVariableQuery" },
        "refresh": 2,
        "type": "query"
      }
    ]
  },
  "time": { "from": "now-1h", "to": "now" },
  "timepicker": {},
  "timezone": "browser",
  "title": "{ProjectName} — Metrics",
  "uid": "{generate-short-uid}",
  "version": 1
}
```

**Panel template for time series (Counter rate):**
```json
{
  "id": 1,
  "type": "timeseries",
  "title": "Request Rate",
  "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
  "datasource": { "type": "prometheus", "uid": "${datasource}" },
  "fieldConfig": {
    "defaults": {
      "color": { "mode": "palette-classic" },
      "custom": { "lineWidth": 2, "fillOpacity": 10 },
      "unit": "reqps"
    }
  },
  "options": { "tooltip": { "mode": "multi", "sort": "desc" } },
  "targets": [
    {
      "datasource": { "type": "prometheus", "uid": "${datasource}" },
      "expr": "sum(rate(metric_total{job=\"$job\", instance=~\"$instance\"}[1m]))",
      "legendFormat": "req/s",
      "refId": "A"
    }
  ]
}
```

**Panel template for Histogram latency (p50/p90/p99):**
```json
{
  "id": 2,
  "type": "timeseries",
  "title": "Latency Percentiles",
  "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
  "fieldConfig": {
    "defaults": { "unit": "s", "custom": { "lineWidth": 2 } }
  },
  "targets": [
    {
      "expr": "histogram_quantile(0.50, sum(rate(metric_bucket{job=\"$job\"}[5m])) by (le))",
      "legendFormat": "p50", "refId": "A"
    },
    {
      "expr": "histogram_quantile(0.90, sum(rate(metric_bucket{job=\"$job\"}[5m])) by (le))",
      "legendFormat": "p90", "refId": "B"
    },
    {
      "expr": "histogram_quantile(0.99, sum(rate(metric_bucket{job=\"$job\"}[5m])) by (le))",
      "legendFormat": "p99", "refId": "C"
    }
  ]
}
```

**Panel template for Gauge (stat):**
```json
{
  "id": 3,
  "type": "stat",
  "title": "Active Connections",
  "gridPos": { "h": 4, "w": 4, "x": 0, "y": 0 },
  "fieldConfig": {
    "defaults": {
      "color": { "mode": "thresholds" },
      "thresholds": {
        "mode": "absolute",
        "steps": [
          { "color": "green", "value": null },
          { "color": "yellow", "value": 80 },
          { "color": "red", "value": 100 }
        ]
      }
    }
  },
  "targets": [
    {
      "expr": "metric_name{job=\"$job\", instance=~\"$instance\"}",
      "legendFormat": "", "refId": "A"
    }
  ]
}
```

---

## Step 5 — Output

1. Print the complete dashboard JSON ready to import via Grafana UI (Dashboards → Import → paste JSON)
2. Save it to `docs/dashboard-{project-name}.json`
3. List every metric found and the panel(s) generated for it
4. Flag any metric that could not be mapped (name or type unclear) — ask for clarification rather than guessing

---

## Rules

- All PromQL queries must include `{job="$job"}` filter so the dashboard respects the variable
- All rate queries use `[1m]` window for responsiveness; histogram quantiles use `[5m]`
- Grid layout: stat panels on row 0 (h:4, w:4–6), time series on rows below (h:8, w:12)
- Never hardcode service names — use `$job` / `$instance` variables throughout
- If a Counter tracks errors/failures, add a separate error-rate panel alongside the success-rate panel
- For labeled metrics, always add a "by label" breakdown panel in addition to the aggregate

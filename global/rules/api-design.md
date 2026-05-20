---
paths:
  - "**/*Controller*.cs"
  - "**/*Endpoint*.cs"
  - "**/*MinimalApi*.cs"
alwaysApply: false
description: "REST API design: HTTP semantics, status codes, versioning, pagination, ProblemDetails, OpenAPI"
---

# API design standards

## Resource naming

```
# GOOD — plural nouns, hierarchical
GET    /api/v1/orders
POST   /api/v1/orders
GET    /api/v1/orders/{id}
PUT    /api/v1/orders/{id}
DELETE /api/v1/orders/{id}
POST   /api/v1/orders/{id}/cancel  ← state transitions as sub-resources

# BAD — verbs in URL
POST   /api/cancelOrder
GET    /api/getOrder?id=123
```

## HTTP status codes

| Scenario | Code |
|----------|------|
| Success with body | 200 |
| Created | 201 + `Location` header |
| Async accepted | 202 |
| Success, no body | 204 |
| Validation failure | 400 |
| Unauthenticated | 401 |
| Forbidden | 403 |
| Not found | 404 |
| Business conflict | 409 |
| Semantically invalid | 422 |
| Rate limited | 429 + `Retry-After` |
| Server error | 500 |

Never return 200 for errors. Never return 500 for business rule violations.

## Versioning

URL versioning: `/api/v1/orders`, `/api/v2/orders`.

Breaking changes that require a new version:
- Removing or renaming a response field
- Changing field type
- Removing an endpoint
- Changing required ↔ optional on request fields

Non-breaking (no version needed): adding optional fields, new endpoints, performance fixes.

## Request DTOs

```csharp
public record CreateOrderRequest(
    [Required] Guid CustomerId,
    [Required, MinLength(1)] IReadOnlyList<OrderItemRequest> Items,
    string? Notes);
```

- `record` type — immutable by default
- `[Required]` on mandatory fields — validated by ASP.NET automatically
- `IReadOnlyList<T>` for collections, never `IEnumerable<T>`
- Optional → nullable with `?`
- Never expose internal DB IDs as request parameters

## Response DTOs

- Never return domain entities or EF types directly
- `IReadOnlyList<T>` for collections
- All `DateTime` in UTC: `CreatedAtUtc`, `UpdatedAtUtc`
- No navigation properties or internal audit fields

## Pagination

Collections always paginated — never return unbounded results.

Cursor-based (preferred for large datasets):
```
GET /api/v1/orders?cursor=xxx&limit=20
Response: { items, nextCursor, hasMore }
```

Offset-based (acceptable for admin/reports):
```
GET /api/v1/orders?page=1&pageSize=20
Response: { items, totalCount, page, pageSize }
```

Maximum pageSize enforced server-side. Default: 20.

## Error responses — ProblemDetails (RFC 7807)

```json
{
  "title": "ValidationException",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "instance": "/api/v1/orders",
  "correlationId": "abc-123",
  "errors": { "customerId": ["must not be empty"] }
}
```

Never expose stack traces, internal paths, or SQL in production error responses.

## OpenAPI annotations (mandatory)

```csharp
[ProducesResponseType(typeof(OrderResponse), 201)]
[ProducesResponseType(typeof(ProblemDetails), 400)]
[ProducesResponseType(typeof(ProblemDetails), 409)]
[ProducesResponseType(401)]
```

Every action must declare ALL possible response codes. Swagger clients are the consumers.

## Idempotency

`POST` endpoints that create resources should support `Idempotency-Key` header for client-side retry safety. Store and return the same result for the same key within a time window.

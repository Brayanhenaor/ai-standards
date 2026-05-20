# API contract design expert

Review or design REST API contracts for the current feature. Apply the lens of an API architect: resource modeling, HTTP semantics, versioning strategy, OpenAPI documentation, error responses, pagination, idempotency, and rate limiting headers.

**Usage:**
- `/user:api-dotnet` — review API changes in current branch
- `/user:api-dotnet [feature description]` — design API contract for a new feature
- `/user:api-dotnet [ControllerName or endpoint path]` — audit a specific endpoint

---

## Step 0 — Load context

Read `CLAUDE.md` first. Extract:
- API versioning strategy already in use
- Standard response wrapper (`ApiResponse<T>` or similar)
- Authentication mechanism
- Pagination pattern already established

Then examine changed files:
```bash
git diff main...HEAD -- "**/*Controller*.cs" "**/*Endpoint*.cs" "**/*MinimalApi*.cs" "**/*.http"
git diff main...HEAD --stat
```

---

## Step 1 — Resource modeling

### REST resource design

```
# GOOD — nouns, plural, hierarchical
GET    /api/v1/orders              — list orders
POST   /api/v1/orders              — create order
GET    /api/v1/orders/{id}         — get order
PUT    /api/v1/orders/{id}         — full replace
PATCH  /api/v1/orders/{id}         — partial update
DELETE /api/v1/orders/{id}         — delete order

GET    /api/v1/orders/{id}/items   — list items of an order
POST   /api/v1/orders/{id}/items   — add item to order

# GOOD — actions as sub-resources when state transitions
POST   /api/v1/orders/{id}/cancel  — cancel (not DELETE — order still exists)
POST   /api/v1/orders/{id}/confirm

# BAD — verbs in URLs
POST   /api/cancelOrder
GET    /api/getOrderById
POST   /api/processPayment
```

Rules:
- Plural nouns for collections: `/orders`, `/users`, `/products`
- Actions as sub-resources on the entity: `POST /orders/{id}/cancel`
- IDs in path segments, not query params: `/orders/{id}` not `/orders?id=`
- Routes in PascalCase matching resource name: `/api/v1/Orders/{id}`

---

## Step 2 — HTTP semantics

### Status codes

| Scenario | Code |
|----------|------|
| Collection retrieved (may be empty) | 200 |
| Single resource retrieved | 200 |
| Resource created | 201 + `Location` header |
| Async operation accepted | 202 |
| Update with no response body | 204 |
| Partial update success | 200 (with updated resource) |
| Bad input / validation failure | 400 |
| Unauthenticated | 401 |
| Authenticated but not authorized | 403 |
| Resource not found | 404 |
| Business conflict (duplicate, out of stock) | 409 |
| Unprocessable semantics (structurally valid but logically wrong) | 422 |
| Too many requests | 429 + `Retry-After` |
| Internal server error | 500 |

```csharp
// 201 Created with Location
return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, _mapper.Map<OrderResponse>(order));

// 204 No Content
return NoContent();

// 409 Conflict (business rule violation)
return Conflict(new ProblemDetails { Title = "OrderAlreadyExists", Detail = $"Order {id} already exists." });
```

### Idempotency

`PUT` and `DELETE` must be idempotent — calling multiple times has the same effect.
`POST` is NOT idempotent — use `Idempotency-Key` header for client-controlled deduplication:

```csharp
[HttpPost]
public async Task<IActionResult> CreateOrder(
    [FromHeader(Name = "Idempotency-Key")] string? idempotencyKey,
    [FromBody] CreateOrderRequest request)
{
    if (idempotencyKey is not null)
    {
        var existing = await _idempotencyStore.GetAsync(idempotencyKey);
        if (existing is not null) return Ok(existing); // return same result
    }
    // ... process
}
```

---

## Step 3 — API versioning

Pick one strategy per project and be consistent. Never mix strategies.

### URL versioning (recommended — explicit, cache-friendly)

```
/api/v1/orders
/api/v2/orders
```

```csharp
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
});

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
```

### Header versioning (alternative — clean URLs)

```
GET /api/orders
Api-Version: 2.0
```

### Breaking changes requiring a new version:
- Removing or renaming a field in the response
- Changing a field's type
- Removing an endpoint
- Changing required → optional (may be non-breaking depending on client)

### Non-breaking (no version bump needed):
- Adding optional response fields
- Adding optional request parameters
- New endpoints
- Performance improvements

---

## Step 4 — Request/response design

### Request DTOs

```csharp
public record CreateOrderRequest(
    [Required] Guid CustomerId,
    [Required, MinLength(1)] IReadOnlyList<OrderItemRequest> Items,
    string? Notes);

public record OrderItemRequest(
    [Required] Guid ProductId,
    [Required, Range(1, 1000)] int Quantity);
```

- `record` for immutability
- `[Required]` on mandatory fields
- `IReadOnlyList<T>` for collections
- Optional fields nullable with `?`
- No internal IDs (auto-increment) in requests — use GUIDs

### Response DTOs

```csharp
public record OrderResponse(
    Guid Id,
    Guid CustomerId,
    string Status,
    decimal Total,
    IReadOnlyList<OrderItemResponse> Items,
    DateTime CreatedAtUtc);
```

- Never return domain entities directly
- Never return `IEnumerable<T>` — use `IReadOnlyList<T>`
- All `DateTime` fields: UTC, include `Utc` suffix in name
- No internal fields (EF navigation properties, audit timestamps not relevant to caller)

### Collection responses

```csharp
public record PagedResponse<T>(
    IReadOnlyList<T> Items,
    int TotalCount,
    int Page,
    int PageSize,
    bool HasNextPage,
    bool HasPreviousPage);
```

---

## Step 5 — Pagination

### Cursor-based (preferred for large datasets)

```
GET /api/v1/orders?cursor=eyJpZCI6MTAwfQ&limit=20

Response:
{
  "items": [...],
  "nextCursor": "eyJpZCI6MTIwfQ",
  "hasMore": true
}
```

Use when:
- Dataset is large and grows continuously
- Real-time data (new items inserted between pages)
- Infinite scroll UX

### Offset-based (acceptable for admin/reporting)

```
GET /api/v1/orders?page=2&pageSize=20

Response:
{
  "items": [...],
  "totalCount": 243,
  "page": 2,
  "pageSize": 20
}
```

Rules:
- Maximum `pageSize` enforced server-side (cap at 100 unless documented otherwise)
- Default `pageSize` if not specified: 20
- `totalCount` only when cheap to compute — skip for cursor-based

---

## Step 6 — Filtering, sorting, search

```
GET /api/v1/orders?status=pending&customerId=xxx&sort=createdAt:desc&q=invoice-123
```

Rules:
- Filter params as query strings, not path segments
- Sort: `sort={field}:{direction}` — field in camelCase, direction `asc`/`desc`
- Search: `q={term}` — full-text or prefix search
- Range filters: `createdFrom=2024-01-01&createdTo=2024-12-31`
- Validate all filter params at boundary — 400 for unknown filter keys

---

## Step 7 — Error responses (ProblemDetails)

All errors use RFC 7807 ProblemDetails. Never custom error envelopes.

```json
// 400 — Validation failure
{
  "type": "https://tools.ietf.org/html/rfc7807",
  "title": "ValidationException",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "instance": "/api/v1/orders",
  "correlationId": "abc-123",
  "errors": {
    "customerId": ["'CustomerId' must not be empty."],
    "items": ["At least one item is required."]
  }
}

// 409 — Business conflict
{
  "title": "ConflictException",
  "status": 409,
  "detail": "Order ORD-456 already exists.",
  "instance": "/api/v1/orders",
  "correlationId": "abc-123"
}

// 500 — Never expose internal detail
{
  "title": "InternalServerError",
  "status": 500,
  "instance": "/api/v1/orders",
  "correlationId": "abc-123"
}
```

---

## Step 8 — OpenAPI / Swagger documentation

Every endpoint must have:

```csharp
/// <summary>
/// Creates a new order for the specified customer.
/// </summary>
[HttpPost]
[ProducesResponseType(typeof(OrderResponse), StatusCodes.Status201Created)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
[ProducesResponseType(StatusCodes.Status401Unauthorized)]
public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request) { ... }
```

Rules:
- `[ProducesResponseType]` for ALL possible status codes — Swagger consumers rely on this
- Summary XML comment on every action
- `[SwaggerRequestExample]` / `[SwaggerResponseExample]` for complex types (optional but valuable)
- Group by tag using `[ApiExplorerSettings(GroupName = "orders")]`

---

## Step 9 — Rate limiting headers

When rate limiting is applied, return standard headers:

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1735689600

HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
```

---

## Step 10 — Output format

### Review mode:

```
## Revisión de API contracts — [branch]

### 🔴 Bloqueantes
- **[archivo:línea]** `[dimensión]` — descripción
  - *Impacto:* cómo afecta a clientes del API
  - *Fix:* corrección concreta

### 🟡 Mejoras
- **[archivo:línea]** — descripción

### 🔵 Sugerencias
- **[archivo:línea]** — descripción

### ℹ️ Cambios de contrato detectados
- Nuevos endpoints: [lista]
- Breaking changes potenciales: [lista]
- Versión requerida: [sí / no — justificación]
```

### Design mode:

```
## Diseño de API — [feature]

### Endpoints propuestos
[Tabla: method | path | auth | description | status codes]

### Request / Response DTOs
[Definición de contratos con tipos]

### Versionado
[¿Se requiere nuevo version? ¿Por qué?]

### Paginación
[Estrategia: cursor / offset — justificación]

### OpenAPI annotations
[ProducesResponseType para cada endpoint]
```

---

## Output rules

- Every breaking change detection is explicit: "this removes/renames field X which clients depend on"
- Status code violations always include the correct code and rationale
- Missing `[ProducesResponseType]` for any possible status always flagged as 🟡
- Versioning recommendations tied to whether the change is truly breaking
- Idempotency concerns flagged for any POST that could be retried by the client

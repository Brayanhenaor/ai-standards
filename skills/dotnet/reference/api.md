# API design

## Resources & verbs

Plural nouns, hierarchical, no verbs in the path. State transitions are sub-resources.

```
GET/POST        /api/v1/orders
GET/PUT/DELETE  /api/v1/orders/{id}
POST            /api/v1/orders/{id}/cancel     # not /cancelOrder
```

## Status codes

`200` body · `201` + `Location` · `202` accepted · `204` no body · `400` validation · `401`
unauthenticated · `403` forbidden · `404` not found · `409` conflict · `422` semantically invalid ·
`429` + `Retry-After` · `500` server. Never `200` for an error; never `500` for a business-rule
violation.

## Versioning

URL versioning (`/api/v1`) via `Asp.Versioning.Http`. A new version is required to remove/rename a
field, change a type, or flip required↔optional. Adding optional fields or new endpoints is
non-breaking.

## Contracts

- Requests and responses are `record` DTOs — never expose entities or EF types.
- `[Required]` on mandatory fields (validated automatically); collections as `IReadOnlyList<T>`.
- All `DateTime` in UTC, named `...Utc`. No navigation properties or internal audit fields in
  responses. Don't expose internal DB IDs.

## Pagination

Collections are always bounded. Cursor-based for large/hot datasets
(`?cursor=&limit=` → `{ items, nextCursor, hasMore }`); offset acceptable for admin/reports. Enforce
a max page size server-side (default ~20).

## Errors & OpenAPI

- Errors are ProblemDetails (RFC 9457) with a correlation id; never leak stack traces or SQL.
- Declare every response code with `[ProducesResponseType]` — clients are generated from it.
- .NET 9/10 ships **built-in OpenAPI** (`builder.Services.AddOpenApi()` / `app.MapOpenApi()`);
  Swashbuckle is no longer the default. Use the built-in document generation unless the project
  already standardized on something else.

## Idempotency

`POST`s that create resources should honor an `Idempotency-Key` header — store the first result and
return it for retries within a window, so client retries don't double-create.

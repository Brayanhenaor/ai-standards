# EF Core

## Don't load to mutate in bulk

```csharp
// BAD — loads every row into memory
var stale = await db.Users.Where(u => !u.IsActive).ToListAsync();
stale.ForEach(u => u.DeletedAt = now);
await db.SaveChangesAsync();

// GOOD — one SQL statement
await db.Users.Where(u => !u.IsActive)
    .ExecuteUpdateAsync(s => s.SetProperty(u => u.DeletedAt, now), ct);

await db.Users.Where(u => u.DeletedAt < cutoff).ExecuteDeleteAsync(ct);
```

## Reads

- Project straight to a DTO with `Select` — don't materialize entities you'll only map. Pulls only
  the columns you need.
- `AsNoTracking()` on every read-only query.
- `AsSplitQuery()` when including multiple collections, to avoid cartesian explosion.

```csharp
var summary = await db.Orders
    .Where(o => o.CustomerId == id)
    .Select(o => new OrderSummary(o.Id, o.Total, o.Customer.Name, o.Items.Count))
    .AsNoTracking()
    .ToListAsync(ct);
```

## Connection resiliency

Enable transient-fault retries on the provider — transient DB drops shouldn't surface as 500s:

```csharp
options.UseSqlServer(cs, o => o.EnableRetryOnFailure());
// Npgsql: o.EnableRetryOnFailure();
```

Note: execution strategies and manual transactions interact — wrap multi-statement work accordingly.

## Compiled queries

For genuinely hot, frequently-run queries, cache the plan with `EF.CompileAsyncQuery`. Measure first;
don't apply blindly.

## Indexes

Add an index (in `IEntityTypeConfiguration<T>`) when a column is used in `WHERE`/`JOIN`/`ORDER BY` on
a hot query, or an FK lacks one (EF doesn't always create FK indexes). Each index has a write cost —
justify it, ideally in an ADR.

```csharp
builder.HasIndex(u => u.Email).IsUnique();
builder.HasIndex(u => new { u.TenantId, u.CreatedAt });
```

## Migrations

- Descriptive names (`AddUserAuditFields`), never `Migration_20240101`.
- Never edit a migration already applied to a shared environment.
- Keep schema changes and data seeding in separate migrations.
- For large tables, go additive: add nullable column → backfill → add constraint, rather than a
  blocking `ALTER`. Test the down-migration before merging.

## Raw SQL & value objects

- Parameterize always (`FromSqlInterpolated`, `SqlQuery<T>`) — never interpolate user input into SQL.
- Map value objects with `HasConversion`; use `OwnsOne` for value objects that don't need their own
  table.

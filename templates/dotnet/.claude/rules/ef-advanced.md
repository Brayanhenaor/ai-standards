---
paths:
  - "**/Migrations/**"
  - "**/*DbContext*.cs"
  - "**/*Repository*.cs"
  - "**/*Configuration.cs"
  - "**/*EntityTypeConfiguration*.cs"
---

# EF Core advanced rules

## Bulk operations

Never load entities just to modify or delete them in bulk:

```csharp
// BAD — loads all entities into memory
var users = await _context.Users.Where(u => !u.IsActive).ToListAsync();
users.ForEach(u => u.DeletedAt = DateTime.UtcNow);
await _context.SaveChangesAsync();

// GOOD — single SQL UPDATE
await _context.Users
    .Where(u => !u.IsActive)
    .ExecuteUpdateAsync(u => u.SetProperty(x => x.DeletedAt, DateTime.UtcNow));

// GOOD — single SQL DELETE
await _context.Users
    .Where(u => u.DeletedAt < DateTime.UtcNow.AddYears(-1))
    .ExecuteDeleteAsync();
```

## Complex queries

Prefer `Join` over multiple `Include` for complex reads:

```csharp
// Prefer explicit projection for reads with multiple related entities
var result = await _context.Orders
    .Where(o => o.CustomerId == customerId)
    .Select(o => new OrderSummaryResponse
    {
        Id = o.Id,
        Total = o.Total,
        CustomerName = o.Customer.Name,
        ItemCount = o.Items.Count
    })
    .AsNoTracking()
    .ToListAsync(cancellationToken);
```

Split queries for large `Include` chains to avoid cartesian explosion:

```csharp
var orders = await _context.Orders
    .Include(o => o.Items)
    .Include(o => o.Payments)
    .AsSplitQuery()   // executes as 3 separate SQL queries
    .AsNoTracking()
    .ToListAsync();
```

## Index design

Propose indexes in the ADR when:
- A column appears in `WHERE`, `JOIN ON`, or `ORDER BY` on a hot query
- A foreign key column lacks an index (EF doesn't create these automatically)
- A composite filter is used together frequently

```csharp
// In IEntityTypeConfiguration<T>
builder.HasIndex(u => u.Email).IsUnique();
builder.HasIndex(u => new { u.TenantId, u.CreatedAt });  // composite
```

Never add indexes blindly — each one has a write cost. Measure first with query execution plans.

## Migrations

- Name describes the change: `AddUserAuditFields`, `RenameOrderStatusColumn` — never `Migration20240101`
- Never modify a migration that has been applied to any non-local environment
- Data migrations (seeding, transforms) go in a separate migration from schema changes
- Test rollback (`dotnet ef database update <previous>`) before merging
- For large tables, prefer additive changes (add nullable column, then populate, then add constraint) over direct ALTER

```csharp
// Data migration pattern
public partial class SeedDefaultRoles : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.InsertData("Roles", new[] { "Id", "Name" },
            new object[] { 1, "Admin" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DeleteData("Roles", "Name", "Admin");
    }
}
```

## Raw SQL

Use only when EF LINQ cannot express the query efficiently:

```csharp
// Acceptable for window functions, CTEs, complex aggregations
var results = await _context.Database
    .SqlQuery<ReportRow>($"SELECT ..., ROW_NUMBER() OVER (...)")
    .ToListAsync();
```

- Always use parameterized queries — never string interpolation with user input
- Map to non-entity types with `SqlQuery<T>` (EF 7+) — never `FromSqlRaw` for projections
- Document why LINQ wasn't sufficient in a comment

## Value converters

Use for domain types stored as primitives:

```csharp
builder.Property(u => u.Email)
    .HasConversion(e => e.Value, v => new Email(v));
```

## Owned entities

For value objects that don't need their own table:

```csharp
builder.OwnsOne(u => u.Address, address =>
{
    address.Property(a => a.Street).HasColumnName("AddressStreet");
    address.Property(a => a.City).HasColumnName("AddressCity");
});
```

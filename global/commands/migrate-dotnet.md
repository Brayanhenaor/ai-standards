# EF Core migration analysis

Analyze all EF Core migrations added in the current branch for safety, correctness, and zero-downtime compatibility. Identify operations that take table locks, block reads/writes, or require multi-step deployment.

**Usage:**
- `/user:migrate-dotnet` — analyze migrations in the current branch vs main
- `/user:migrate-dotnet [MigrationName]` — analyze a specific migration

---

## Step 0 — Discover migrations

```bash
git diff main...HEAD --name-only | grep -i "Migrations"
git diff main...HEAD -- "**/Migrations/**"
dotnet ef migrations list 2>/dev/null | tail -20
```

Read every migration file added or modified in this branch. Read the `DbContext` and all `IEntityTypeConfiguration<T>` files affected.

---

## Step 1 — Analyze each migration

For every migration found, evaluate ALL of the following:

---

### 1. Naming quality

- Name describes the schema change in business terms: `AddUserAuditFields`, `RenameOrderStatusColumn`, `CreateInvoiceIndexOnCustomerId`
- Never: `Migration20240101`, `AutoMigration`, `Update1`
- Past tense or descriptive noun, not `ChangeSomething` vaguely

---

### 2. Down() implementation

- `Down()` method must be a complete, correct inverse of `Up()`
- `Down()` that is empty or throws `NotSupportedException` → 🔴 blocker
- Exception: `InsertData` in `Up()` → `DeleteData` in `Down()` (reversible)
- For complex backfills in `Up()`, `Down()` may be a no-op if data loss is acceptable — but must be documented

```csharp
// ✅ Complete rollback
protected override void Down(MigrationBuilder mb)
{
    mb.DropColumn("IsVerified", "Users");
}
```

---

### 3. Zero-downtime risk analysis

**Operations that take an exclusive table lock (DDL locks):**

| Operation | Lock type | Risk |
|-----------|-----------|------|
| `AddColumn` (NOT NULL, no default) | Exclusive | Blocks all reads + writes during alter |
| `AddColumn` (NOT NULL + DEFAULT) | Exclusive | Rewrites entire table on SQL Server |
| `DropColumn` | Exclusive | Safe if app no longer references it |
| `RenameColumn` | Exclusive | App must not reference old name |
| `AlterColumn` (type change) | Exclusive | Rewrites table on most engines |
| `CreateIndex` (without CONCURRENTLY) | Share lock | Blocks writes on Postgres |
| `AddForeignKey` | Exclusive | Validates all existing rows |
| `AddUniqueConstraint` | Exclusive | Validates all existing rows |

**For each operation found, classify:**
- 🔴 **Table lock on large table** (>100K rows estimated) — requires multi-step deployment
- 🟡 **Table lock on small table** — acceptable with maintenance window
- ✅ **Non-locking** — safe for rolling deploy

---

### 4. NOT NULL column addition pattern

Adding NOT NULL column to existing table without server-default is a production killer.

**Safe multi-step pattern (3 migrations, 3 deploys):**

```
Step 1 — Migration: Add column as nullable
  mb.AddColumn<string>("Status", "Orders", nullable: true);

Deploy v1 — Code writes the column

Step 2 — Migration: Backfill existing rows
  mb.Sql("UPDATE Orders SET Status = 'Pending' WHERE Status IS NULL");

Deploy v2 — No code change

Step 3 — Migration: Add NOT NULL constraint
  mb.AlterColumn<string>("Status", "Orders", nullable: false);

Deploy v3 — Final state
```

**Detect violations:**
- `AddColumn` with `nullable: false` and no `defaultValue` on a table that likely has data → 🔴
- `AlterColumn` changing `nullable: true` → `nullable: false` without visible backfill → 🔴

---

### 5. Column/table rename safety

Direct rename breaks apps deployed before the migration:

```
// 🔴 UNSAFE — single rename, rolling deploy fails
mb.RenameColumn("OldName", "Users", "NewName");

// ✅ SAFE — expand-contract (3 steps)
Step 1: AddColumn NewName (nullable), copy data from OldName
Step 2: Update app to write both columns, read from NewName
Step 3: DropColumn OldName
```

Detect: any `RenameColumn` or `RenameTable` in a service with zero-downtime requirements.

---

### 6. Index creation

**SQL Server:** `CREATE INDEX` with ONLINE = ON (EF default for most ops) — non-blocking.
Verify: does the migration specify `IsCreatedConcurrently()` where the DB is Postgres?

**Postgres without CONCURRENTLY:**
- `CreateIndex` takes a ShareRowExclusiveLock — blocks writes
- For large tables, must use `migrationBuilder.Sql("CREATE INDEX CONCURRENTLY ...")` via raw SQL

**Detect:** large table + `CreateIndex` + Postgres context → warn about CONCURRENTLY.

---

### 7. Data migrations

- Data migrations (INSERT, UPDATE, backfill) must be SEPARATE from schema migrations
- One migration = one concern: schema change OR data transform, never both
- Backfill of large datasets must be chunked:

```csharp
// BAD — locks table, times out on large datasets
mb.Sql("UPDATE Orders SET Status = 'Active' WHERE Status IS NULL");

// GOOD — chunked via raw SQL or separate background job
mb.Sql(@"
    DECLARE @batchSize INT = 5000;
    WHILE EXISTS (SELECT 1 FROM Orders WHERE Status IS NULL)
    BEGIN
        UPDATE TOP (@batchSize) Orders SET Status = 'Active' WHERE Status IS NULL;
    END
");
```

---

### 8. Foreign key additions

- `AddForeignKey` validates all existing rows — fails if orphan records exist
- Must run cleanup (DELETE orphans or SET NULL) BEFORE adding FK
- Detect: `AddForeignKey` without preceding cleanup migration → ask if referential integrity guaranteed

---

### 9. Sensitive data in migration

- No hardcoded passwords, emails, or PII in `InsertData` / seed data
- No connection strings or secrets in migration files

---

### 10. Migration isolation

- Only migrations from the current feature/branch — no unrelated schema changes included
- `Down()` works independently — partial rollback does not corrupt DB state
- Migration applies cleanly from the previous migration state (not from HEAD)

---

## Step 2 — Deployment plan recommendation

Based on findings, output one of:

**Single-deploy migration** — no locking operations, safe to apply in rolling deploy:
```
dotnet ef database update [MigrationName]
```

**Multi-step migration** — requires sequential deploys with code changes between steps:
```
Deploy 1: apply Migration_AddNullableColumn
Deploy 2: update app code to write new column → apply Migration_BackfillColumn
Deploy 3: apply Migration_MakeColumnNonNull
```

**Maintenance window required** — DDL lock on large table unavoidable:
- Estimate lock duration based on table size
- Suggest maintenance window or use of pt-online-schema-change / gh-ost

---

## Step 3 — Output format

```
## Análisis de migrations — [branch]

### 🔴 Bloqueantes
Deben resolverse antes del despliegue a producción.

- **[MigrationName]** `[operación]` — descripción del riesgo
  - *Impacto:* tabla afectada, tipo de lock, duración estimada
  - *Patrón correcto:* secuencia de pasos para hacerlo seguro

### 🟡 Riesgos con ventana de mantenimiento
Operaciones que toman lock pero son manejables con coordinación.

- **[MigrationName]** — descripción
  - *Recomendación:* ejecutar en horario de bajo tráfico

### ✅ Migraciones seguras
- [MigrationName] — descripción breve de la operación

### Plan de despliegue recomendado
[Pasos ordenados con qué migrar y qué deployar en cada paso]

### ℹ️ Recordatorios
- Probar rollback: `dotnet ef database update [MigrationAnterior]`
- Hacer backup antes de aplicar en producción
- migration-guard hook activo — `ef database update` bloqueado para Claude
```

---

## Output rules

- Every finding references the exact migration file and method (`Up()` line number)
- For 🔴 findings, provide the complete multi-step alternative
- Never approve a migration that drops columns still referenced in app code without confirming the column is already removed from code
- Cross-reference with `migration-guard.sh` hook — it blocks Claude from running `ef database update` automatically

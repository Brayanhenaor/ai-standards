---
name: migrate
description: Analyze a database migration for safety before it runs against a real environment. Use when a change adds or edits migrations or alters schema. Checks for blocking locks, data loss, and zero-downtime concerns, and recommends an expand-contract path. Universal; the active pack supplies tool specifics (e.g. EF Core).
---

# Migrate — migration safety

Schema changes are among the riskiest things you ship — they can lock tables, drop data, or break the
currently-running version mid-deploy. Analyze the migration before it touches a shared environment.

## What to check

- **Data loss.** Dropping a column/table, narrowing a type, or adding a `NOT NULL` without a default
  on a populated table. Flag anything irreversible; confirm there's a backup/rollback story.
- **Blocking locks.** On large tables, operations that rewrite or take long locks (adding a non-null
  column with default on some engines, certain index builds, type changes) can stall production.
  Prefer non-blocking variants (concurrent index builds, additive steps).
- **Zero-downtime / running-version compatibility.** During a rolling deploy, old and new code run at
  once. The migration must be compatible with **both**. Don't remove/rename a column the currently
  deployed code still reads or writes.
- **Reversibility.** A safe down-migration exists and has been considered. Test rollback before merge.
- **Schema vs data.** Keep schema changes and data backfills in **separate** migrations — mixing them
  complicates rollback and lengthens locks.

## Expand–contract (the safe path for breaking changes)

1. **Expand** — add the new shape (nullable column, new table) without touching the old. Deploy.
2. **Migrate data & code** — backfill in batches; switch code to the new shape. Deploy.
3. **Contract** — once nothing uses the old shape, remove it. Deploy.

Each step is independently deployable and reversible. Rename = add new + backfill + switch + drop old,
never an in-place rename on a live column.

## Report

For each risk: what it is, the failure it causes (lock/lost data/broken running version), and the
safer rewrite. Give a clear verdict: safe to run, or rework along expand–contract first. The active
pack covers tool specifics — e.g. EF Core: additive steps, `ExecuteUpdate` backfills, separate data
migrations (see the dotnet pack's `data-ef.md`).

Reply in the developer's language; keep code and SQL identifiers in English.

---
name: migration-semantic-drift-audit
description: Use when an Alembic migration adds, drops, or changes the semantics of a column on a shared table, before claiming the change is safe. Symptoms include altered column types, changed nullability, renamed columns, new constraints on existing data, or modified default values on tables read or written by more than one service.
---

# Migration Semantic Drift Audit

## Why this matters

CI green is not safety. Existing tests often mock the SQL response — mocks freeze the *old* shape of the table and will keep passing even when the migration breaks every real writer in production.

A migration that changes a shared table's schema or semantics requires auditing **every** writer and reader, not just the test that exercises the migration.

## When to use

Trigger on migrations that:
- Change column type, nullability, or default
- Rename or drop a column read/written elsewhere
- Add a `NOT NULL` or `UNIQUE` constraint to existing data
- Modify enum values
- Change the meaning of a status/state column
- Touch any table written by 2+ modules

Skip for: migrations that only add a brand-new table or column with no existing readers.

## Procedure

1. **Identify the changed table**. Read the migration file (`alembic/versions/*.py`).
2. **Find every writer**:
   ```bash
   grep -rn '<table_name>' packages/prism/app --include='*.py' \
     | grep -E '(insert|update|delete|INSERT|UPDATE|DELETE|\.add\(|\.merge\()'
   ```
3. **Find every reader**:
   ```bash
   grep -rn '<table_name>' packages/prism/app --include='*.py'
   ```
4. **For each callsite**, verify:
   - Does it pass the new constraint? (e.g. provides the now-NOT-NULL value)
   - Does it read columns that still exist?
   - Does its assumption about the column's *meaning* still hold?
5. **Audit tests for mock drift**. For each test that exercises code touching the table:
   - Does it use a SQL mock or fake?
   - If yes, does the mock still match the new schema? Mock-based tests can pass while reality breaks.
   - Prefer a real DB integration test over a refreshed mock.

## Output format

Produce a table:

| Callsite (file:line) | Operation | Risk | Action |
|---|---|---|---|
| `app/services/x.py:42` | INSERT | NULL passed for new NOT NULL col | Backfill or add default |
| `tests/test_y.py:101` | mocked SELECT | mock returns old shape | Convert to integration test |

## Red flags

- "CI is green so it's fine" — mocks may be lying.
- "Only one service writes this table" — verify with grep, don't assume.
- "The migration has a default" — check whether existing rows actually got backfilled.

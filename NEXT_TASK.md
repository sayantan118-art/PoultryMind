# NEXT_TASK.md

**Task ID:** T-001
**Priority:** P0 (blocks everything else)
**Stage:** 0 → 1 (repository foundation / database foundation)

## Objective

Fix an invalid import that currently prevents the SQLAlchemy model layer from being imported at all: `Decimal` is imported from `sqlalchemy` in four model files, but `sqlalchemy` does not export a `Decimal` type — the correct SQLAlchemy type for fixed-precision numbers is `Numeric`. As written, `from sqlalchemy import ..., Decimal, ...` raises `ImportError` the moment any of these modules is loaded, which means Alembic cannot currently see any model metadata and no test that imports `apps.api.main` (which pulls in the model graph indirectly) can pass reliably today.

## Files affected

- `apps/api/models/master.py`
- `apps/api/models/feed.py`
- `apps/api/models/inventory.py`
- `apps/api/models/vaccine.py`

## Dependencies

None. This is the first fix in the repository — nothing needs to exist before this.

## Implementation tasks

1. In each of the four files, change the import line from `... Decimal, ...` to `... Numeric, ...`.
2. Replace every usage of `Decimal(p, s)` as a column type with `Numeric(p, s)` (same precision/scale arguments, e.g. `Column(Decimal(8, 3), ...)` → `Column(Numeric(8, 3), ...)`).
3. Replace bare `Decimal` (no precision args, e.g. `length_ft = Column(Decimal)` in `master.py`) with `Numeric` (also bare, or give it a sensible precision if one is obvious from `infra/aws/rds_schema.sql` — check the corresponding column there; `length_ft`/`width_ft` are untyped `DECIMAL` in the SQL file too, so bare `Numeric` is fine).
4. Do not touch any other logic in these files as part of this task — this is a type-import fix only. (The primary-key naming mismatch and the `hdp_percent`/mutable-default issues in `flock.py` are separate tasks, T-002 and T-003 — leave them for those tasks.)
5. After fixing, confirm nothing else in the four files still references `Decimal` (grep for it) and confirm no other model file has the same mistake (`grep -rn "Decimal" apps/api/models/*.py` should show zero remaining SQLAlchemy-type usages of `Decimal`; Python's own `decimal.Decimal` is not used anywhere in these files, so a clean zero-match is expected).

## Acceptance criteria

- `grep -rn "Decimal" apps/api/models/*.py` returns no results.
- Each of the four fixed files imports successfully on its own:
  ```bash
  cd apps/api && python3 -c "from models import master, feed, inventory, vaccine"
  ```
  runs with no exception (note: this will still likely hit the separate PK/FK issues from T-002 if run against a real engine/metadata build — for T-001, success means the `ImportError` on `Decimal` is gone; a clean full-metadata build is T-002/T-004's job, not this task's).
- No other file in the model layer or elsewhere in `apps/api` references `Decimal` as a SQLAlchemy column type.

## Tests

No new test file is required for this narrow a fix, but before marking this done, run:
```bash
cd apps/api && python3 -c "import ast; [ast.parse(open(f).read()) for f in ['models/master.py','models/feed.py','models/inventory.py','models/vaccine.py']]"
```
to confirm no syntax errors were introduced, and the import check in Acceptance Criteria above.

## Verification

```bash
grep -rn "Decimal" apps/api/models/*.py    # expect: no output
cd apps/api
python3 -c "from models import master"
python3 -c "from models import feed"
python3 -c "from models import inventory"
python3 -c "from models import vaccine"
```
All four import commands should exit with no traceback.

## Definition of Done

- [ ] All four files updated, `Decimal` → `Numeric` everywhere it was used as a column type.
- [ ] `grep` confirms zero remaining occurrences.
- [ ] All four modules import cleanly in isolation.
- [ ] `IMPLEMENTATION_STATUS.md` created (if it doesn't exist yet — this is the first task, so it likely doesn't) and updated: T-001 moved to "Completed," T-002 set as "Next recommended task."
- [ ] Session handoff written per `DEVELOPMENT_GUIDE.md` Part 12.

## After this task

Move immediately to **T-002** (resolve the primary-key naming mismatch between the generic `id` in `AuditMixin` and the domain-specific PK names used throughout `infra/aws/rds_schema.sql` and `packages/shared-types/src/index.ts`) — see `DEVELOPMENT_GUIDE.md` Part 7 for its full spec. Do not skip ahead to routers, auth, or the dashboard before Stage 1 (database foundation) is complete — see `DEVELOPMENT_GUIDE.md` Part 4.

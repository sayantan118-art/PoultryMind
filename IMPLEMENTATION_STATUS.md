# Implementation Status

**Last updated:** 2026-09-02 by GitHub Copilot

## Current phase
Stage 0 → 1 — repository foundation / database foundation

## Current milestone
T-002 — Resolve the domain-specific PK/FK mismatch across the model layer

## Completed tasks
- T-001 — Fixed SQLAlchemy `Decimal` usage to `Numeric` across the affected model files; verified the model modules import successfully and no `Decimal` matches remain in `apps/api/models/*.py`.
- T-002 — Removed the generic `id` key from `AuditMixin`, declared explicit domain-specific PK columns for each model, updated all `ForeignKey(...)` strings to match the schema's `<table>.<column>` naming, and verified there are no remaining `.id` FK references in the model layer.
- T-003 — Fixed the remaining flock defaults: `hdp_percent` stays aligned to the schema's `DECIMAL(6,3)` and `validation_flags` now uses a safe non-shared default (`default=list`) instead of a mutable list literal.
- T-004 — Wired all model classes into `apps/api/models/__init__.py` so `Base.metadata` can be resolved as a single graph.

## In progress
- None at this time.

## Blocked tasks
- None at this time.

## Known issues
- Runtime database validation remains environment-blocked because Docker/pg_config are unavailable in this session, but the model metadata alignment itself is now complete at the code level.

## Architecture decisions log
- 2026-09-02 — Matched the SQLAlchemy model names to the design-source schema in `infra/aws/rds_schema.sql` and the shared-types definitions instead of the generic `id` pattern.
- 2026-09-02 — The flock JSONB default was fixed to `default=list` to avoid a shared mutable default while keeping the schema contract intact.

## Assumptions made under ambiguity
- 2026-09-02 — The fix scope remained limited to model PK/FK naming and safe JSONB defaults, as specified by the Stage 1 backlog; no unrelated schema changes were introduced.

## Next recommended task
Stage 1 follow-up: confirm the metadata graph can build cleanly through a real Alembic or SQLAlchemy import once the local Postgres toolchain is available, then proceed to the next backlog item.

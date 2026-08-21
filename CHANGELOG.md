# Changelog

## 0.1.0 — 2026-08-21

- Reflection-based map: associations, Active Storage attachments, app concerns, non-boilerplate
  columns, unique indexes with partial predicates, check constraint names, ownership path, STI.
- `agents:data_model` (write) and `agents:data_model:check` (verify, exit 1 with diff).
- `db:schema:dump*` enhancement that regenerates the block, including multi-database apps.
- `schema_map:install` generator: initializer, verify-only guard test, failing pre-commit hook,
  markers and first render.
- `SchemaMap::TestHelper#assert_data_model_map_current`.
- Fail-closed pending-migrations guard: write/check refuse while the database is behind; the schema
  dump enhancement still regenerates because the dump mirrors the live database.
- SQLite and PostgreSQL test runs.

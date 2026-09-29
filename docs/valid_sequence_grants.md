# Valid Sequence Grants

A light knowledge base for the `sequence_grants` entries in this module.
Sequence grants control what a role can do with the counters that back
`serial`, `bigserial`, and identity columns. They only take effect once the
role has `USAGE` on the schema (see
[valid_schema_grants.md](./valid_schema_grants.md)) and `CONNECT` on the
database.

## Privileges

PostgreSQL defines three privileges at the sequence level.

| Privilege | What it allows                                                                 | Typical roles                   |
| --------- | ------------------------------------------------------------------------------ | ------------------------------- |
| `USAGE`   | Call `nextval()` and `currval()`. This is what an `INSERT` into a serial column needs. | Read-write and migration roles  |
| `SELECT`  | Call `currval()` and read the sequence's current state with a plain `SELECT`. | Every role that touches the table |
| `UPDATE`  | Call `nextval()` and `setval()`. `setval()` resets the counter, so this is a structural privilege. | Migration and pipeline roles    |

`ALL` is accepted by PostgreSQL as shorthand for all three. Prefer listing the
privileges explicitly so the intent is visible in the config.

Note the overlap. Both `USAGE` and `UPDATE` allow `nextval()`. The practical
difference is that `UPDATE` also unlocks `setval()`.

## How they combine

- **Read-only roles** get `USAGE` and `SELECT`. `SELECT` alone is enough to
  inspect a sequence, and `USAGE` is harmless but common in this repo's
  examples.
- **Read-write app roles** get `USAGE`, `SELECT`, `UPDATE`. This is the
  standard set and is what an application needs to insert rows into tables
  with generated ids.
- **Migration roles** get the same three. There is no higher tier at the
  sequence level.
- **Revoking everything** is done by passing an empty `privileges` list.

## Why sequence grants exist separately

A table grant does not cascade to the sequence behind its id column. A role
with `INSERT` on a table but no `USAGE` on its sequence fails with a
permission error on the first insert. This is the most common reason a
freshly granted read-write role still cannot write.

## Scope of a sequence grant

By default a `sequence_grants` entry applies to **every sequence that currently
exists** in the schema.

1. **New sequences are not covered.** Use `default_privileges` with
   `object_type: sequence` and the migration role as `owner` to cover
   sequences created by future migrations.
2. **You can narrow the scope.** The optional `objects` list restricts the
   grant to named sequences.

## Related layers

1. **Database** (`database_grants`): `CONNECT`, `CREATE`, `TEMPORARY`.
2. **Schema** (`schema_grants`): `USAGE`, `CREATE`.
3. **Objects** (`table_grants`, `sequence_grants`, `default_privileges`):
   the privileges listed above.

## Example

```yaml
sequence_grants:
  # role defaults to the parent role's name
  - { database: llm_chat_app, schema: app, object_type: sequence, privileges: ["USAGE", "SELECT", "UPDATE"] }

default_privileges:
  # cover sequences the migration role creates later
  - { database: llm_chat_app, schema: app, owner: role_service_migration, object_type: sequence, privileges: ["USAGE", "SELECT", "UPDATE"] }
```

## References

- PostgreSQL `GRANT` documentation: <https://www.postgresql.org/docs/current/sql-grant.html>
- PostgreSQL sequence functions: <https://www.postgresql.org/docs/current/functions-sequence.html>
- Provider resource `postgresql_grant`: <https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant>

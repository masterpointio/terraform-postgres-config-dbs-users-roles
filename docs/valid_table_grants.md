# Valid Table Grants

A light knowledge base for the `table_grants` entries in this module. Table
grants control what a role can do *with the rows and structure of tables* in a
schema. They only take effect once the role already has `USAGE` on the schema
(see [valid_schema_grants.md](./valid_schema_grants.md)) and `CONNECT` on the
database.

## Privileges

PostgreSQL defines seven privileges at the table level.

| Privilege    | What it allows                                                                                  | Typical roles                     |
| ------------ | ----------------------------------------------------------------------------------------------- | --------------------------------- |
| `SELECT`     | Read rows. Also required to reference columns in `UPDATE`, `DELETE`, or a `WHERE` clause.        | Every role that touches data      |
| `INSERT`     | Add new rows.                                                                                   | Read-write and migration roles    |
| `UPDATE`     | Change existing rows. Needs `SELECT` too in practice.                                           | Read-write and migration roles    |
| `DELETE`     | Remove individual rows. Needs `SELECT` too in practice.                                         | Read-write and migration roles    |
| `TRUNCATE`   | Empty the whole table in one step. Bypasses row-level `DELETE` triggers.                        | Migration and pipeline roles only |
| `REFERENCES` | Create a foreign key that points at this table.                                                 | Migration roles only              |
| `TRIGGER`    | Create triggers on the table.                                                                   | Migration roles only              |

`ALL` is accepted by PostgreSQL as shorthand for all seven. Prefer listing the
privileges explicitly so the intent is visible in the config.

## How they combine

- **Read-only roles** get `SELECT` only.
- **Read-write app roles** get `SELECT`, `INSERT`, `UPDATE`, `DELETE`. This is
  the standard DML set and is what most application users need.
- **Pipeline roles** often add `TRUNCATE` so a load job can reset a staging
  table quickly.
- **Migration roles** get the DML set plus `TRUNCATE` and `REFERENCES`, and
  sometimes `TRIGGER`. These are structural privileges, so keep them off
  application logins.
- **Revoking everything** is done by passing an empty `privileges` list.

## Scope of a table grant

By default a `table_grants` entry applies to **every table that currently
exists** in the schema. Two things follow from that:

1. **New tables are not covered.** A table created after the grant runs gets
   nothing until the grant is re-applied. Use `default_privileges` with the
   migration role as `owner` to cover tables created later.
2. **You can narrow the scope.** The optional `objects` list restricts the grant
   to named tables instead of the whole schema.

## Related layers

Table grants are the bottom layer of a three-layer stack.

1. **Database** (`database_grants`): `CONNECT`, `CREATE`, `TEMPORARY`.
2. **Schema** (`schema_grants`): `USAGE`, `CREATE`.
3. **Objects** (`table_grants`, `sequence_grants`, `default_privileges`):
   the privileges listed above.

Sequences are granted separately with `sequence_grants`. A role with `INSERT`
on a table that uses a serial or identity column also needs `USAGE` on the
backing sequence.

## Example

```yaml
table_grants:
  # role defaults to the parent role's name
  - { database: llm_chat_app, schema: app, object_type: table, privileges: ["SELECT", "INSERT", "UPDATE", "DELETE"] }
  # restrict to specific tables
  - { database: llm_chat_app, schema: app, object_type: table, objects: ["audit_log"], privileges: ["SELECT"] }
```

## References

- PostgreSQL `GRANT` documentation: <https://www.postgresql.org/docs/current/sql-grant.html>
- PostgreSQL `ALTER DEFAULT PRIVILEGES`: <https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html>
- Provider resource `postgresql_grant`: <https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant>

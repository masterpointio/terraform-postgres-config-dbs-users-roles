# Valid Schema Grants

A light knowledge base for the `schema_grants` entries in this module. Schema
grants control what a role can do *with a schema itself*. They do not grant
access to the tables, sequences, or functions inside it. Those are handled by
`table_grants`, `sequence_grants`, and `default_privileges`.

## Privileges

PostgreSQL defines exactly two privileges at the schema level.

| Privilege | What it allows                                                                       | Typical roles                          |
| --------- | ------------------------------------------------------------------------------------ | -------------------------------------- |
| `USAGE`   | Look up and reference objects inside the schema. Required before any table grant works. | Every role that reads or writes data   |
| `CREATE`  | Create new objects (tables, views, sequences, functions) inside the schema.          | Migration or owner roles only          |

`ALL` is accepted by PostgreSQL as shorthand for both. Prefer listing the
privileges explicitly so the intent is visible in the config.

## How they combine

- **Read-only and read-write app roles** get `USAGE` only. They can see and
  use objects but cannot change the schema's shape.
- **Migration roles** get `USAGE` and `CREATE`. They own DDL for the schema.
- **A role with `CREATE` but not `USAGE`** can create objects it then cannot
  reference. This is almost never what you want.
- **Revoking everything** is done by passing an empty `privileges` list. The
  example uses this to strip the default `public` schema access.

## Related layers

Schema grants sit in the middle of a three-layer stack. A role needs the layer
above before the layer below has any effect.

1. **Database** (`database_grants`): `CONNECT`, `CREATE`, `TEMPORARY`.
2. **Schema** (`schema_grants`): `USAGE`, `CREATE`.
3. **Objects** (`table_grants`, `sequence_grants`, `default_privileges`):
   `SELECT`, `INSERT`, `UPDATE`, `DELETE`, and so on.

## Example

```yaml
schema_grants:
  # role defaults to the parent role's name
  - { database: llm_chat_app, schema: app, object_type: schema, privileges: ["USAGE", "CREATE"] }
```

## References

- PostgreSQL `GRANT` documentation: <https://www.postgresql.org/docs/current/sql-grant.html>
- Provider resource `postgresql_grant`: <https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant>

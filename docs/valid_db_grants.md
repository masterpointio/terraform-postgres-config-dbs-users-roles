# Valid Database Grants

A light knowledge base for the `database_grants` entry in this module.
Database grants are the top of the privilege stack. A role with no database
privileges cannot reach anything inside it, no matter what schema or table
grants it holds.

Unlike the other grant types, `database_grants` is a single object per role,
not a list, because a role only needs one grant per database.

## Privileges

PostgreSQL defines three privileges at the database level.

| Privilege   | What it allows                                                                   | Typical roles                  |
| ----------- | -------------------------------------------------------------------------------- | ------------------------------ |
| `CONNECT`   | Open a session against the database. Without it every login is refused.          | Every role                     |
| `CREATE`    | Create new schemas inside the database.                                          | Migration roles only           |
| `TEMPORARY` | Create temporary tables for the life of a session. `TEMP` is an accepted alias.  | Migration and pipeline roles   |

`ALL` is accepted by PostgreSQL as shorthand for all three. Prefer listing the
privileges explicitly so the intent is visible in the config.

## How they combine

- **Application roles**, read-only or read-write, get `CONNECT` only. They
  work inside schemas that already exist.
- **Migration roles** get `CONNECT`, `CREATE`, `TEMPORARY`. `CREATE` lets them
  add schemas, and `TEMPORARY` supports scratch tables during a migration.
- **Pipeline roles** may get `TEMPORARY` if their load jobs stage data in temp
  tables. Most do not need `CREATE`.
- **Revoking everything** is done by passing an empty `privileges` list.

## The `public` role

Every new PostgreSQL database grants `CONNECT` and `TEMPORARY` to the built-in
`public` pseudo-role, which every other role is a member of. That means any
role can connect until you revoke it. The llm_chat_app example does this with a
separate grant that sets `public`'s privileges to an empty list, so only roles
with an explicit `CONNECT` can get in.

## Group roles and login roles

`CONNECT` is inheritable. The pattern in this repo is to grant it on a
non-login group role such as `role_service_rw`, then have login roles like
`service_fastapi_rw` inherit from the group. The login role never needs its own
`database_grants` entry.

## Related layers

Database grants are the top layer of a three-layer stack. Nothing below works
without `CONNECT`.

1. **Database** (`database_grants`): the privileges listed above.
2. **Schema** (`schema_grants`): `USAGE`, `CREATE`. See
   [valid_schema_grants.md](./valid_schema_grants.md).
3. **Objects** (`table_grants`, `sequence_grants`, `default_privileges`). See
   [valid_table_grants.md](./valid_table_grants.md) and
   [valid_sequence_grants.md](./valid_sequence_grants.md).

## Example

```yaml
database_grants:
  # role defaults to the parent role's name
  database: llm_chat_app
  object_type: database
  privileges: ["CONNECT", "CREATE", "TEMPORARY"]
```

## References

- PostgreSQL `GRANT` documentation: <https://www.postgresql.org/docs/current/sql-grant.html>
- PostgreSQL default privileges for `public`: <https://www.postgresql.org/docs/current/ddl-priv.html>
- Provider resource `postgresql_grant`: <https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant>

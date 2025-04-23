locals {
  roles_with_passwords = [for idx, role_data in var.roles : merge(role_data,
    {
      role : merge(role_data["role"],
        lookup(role_data["role"], "password", null) != null ? # Or if it's empty string?
        {
          password : role_data["role"]["password"]
        } :
        {
          password : random_password.user_password[idx].result
        }
      )
    }
  )]

  _database_grants    = [for role in local.roles_with_passwords : role.database_grants if try(role.database_grants, null) != null]
  _default_privileges = flatten([for role in local.roles_with_passwords : role.default_privileges if try(role.default_privileges, null) != null])
  _schema_grants      = [for role in local.roles_with_passwords : role.schema_grants if try(role.schema_grants, null) != null]
  _sequence_grants    = [for role in local.roles_with_passwords : role.sequence_grants if try(role.sequence_grants, null) != null]
  _table_grants       = [for role in local.roles_with_passwords : role.table_grants if try(role.table_grants, null) != null]
}

resource "postgresql_database" "logical_db" {
  for_each         = { for database in var.databases : database.name => database }
  name             = each.key
  connection_limit = each.value.connection_limit
}

# If no password passed in, then use this to generate one
resource "random_password" "user_password" {
  count = length(var.roles)

  length = 33
  # Leave special characters out to avoid quoting and other issues.
  # Special characters have no additional security compared to increasing length.
  special          = false
  override_special = "!#$%^&*()<>-_"
}

# In Postgres 15, now new users cannot create tables or write data to Postgres public schema by default. You have to grant create privilege to the new user manually.
# https://www.postgresql.org/docs/current/ddl-priv.html#DDL-PRIV-CREATE
resource "postgresql_role" "role" {
  for_each = { for role in local.roles_with_passwords : role.role.name => role }

  name                      = each.value.role.name
  superuser                 = each.value.role.superuser
  create_database           = each.value.role.create_database
  create_role               = each.value.role.create_role
  inherit                   = each.value.role.inherit
  login                     = each.value.role.login
  replication               = each.value.role.replication
  bypass_row_level_security = each.value.role.bypass_row_level_security
  connection_limit          = each.value.role.connection_limit
  encrypted_password        = each.value.role.encrypted_password
  password                  = each.value.role.password
  roles                     = each.value.role.roles
  search_path               = each.value.role.search_path
  valid_until               = each.value.role.valid_until
  skip_drop_role            = each.value.role.skip_drop_role
  skip_reassign_owned       = each.value.role.skip_reassign_owned
  statement_timeout         = each.value.role.statement_timeout
  assume_role               = each.value.role.assume_role

  depends_on = [postgresql_database.logical_db]
}

resource "postgresql_grant" "database_access" {

  for_each = { for grant in local._database_grants : format("%s-%s", grant.role, grant.database) => grant }

  role        = each.value.role
  database    = each.value.database
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_db, postgresql_role.role]
}

resource "postgresql_grant" "schema_access" {

  for_each = { for grant in local._schema_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_db, postgresql_role.role]
}

resource "postgresql_grant" "table_access" {

  for_each = { for grant in local._table_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges
  objects     = each.value.objects

  depends_on = [postgresql_database.logical_db]
}

resource "postgresql_grant" "sequence_access" {

  for_each = { for grant in local._sequence_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_db, postgresql_role.role]
}

resource "postgresql_default_privileges" "privileges" {

  for_each = { for grant in local._default_privileges : format("%s-%s-%s-%s", grant.role, grant.database, grant.schema, grant.object_type) => grant }

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  owner       = each.value.owner
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_db, postgresql_role.role]
}

locals {
  # Roles without an explicit password get one from random_password.
  _roles_with_passwords = [for idx, role in var.roles : merge(role, {
    password = role.password != null ? role.password : random_password.user_password[idx].result
  })]

  # Grant entries may omit `role`; when they do, it defaults to the parent role's name.
  _default_privileges = flatten([
    for role in local._roles_with_passwords : [
      for grant in coalesce(role.default_privileges, []) : merge(grant, { role = coalesce(grant.role, role.name) })
    ]
  ])
  default_privileges_map = { for grant in local._default_privileges : format("%s-%s-%s-%s", grant.role, grant.database, grant.schema, grant.object_type) => grant }

  _database_grants = [
    for role in local._roles_with_passwords : merge(role.database_grants, { role = coalesce(role.database_grants.role, role.name) })
    if try(role.database_grants, null) != null
  ]
  database_grants_map = { for grant in local._database_grants : format("%s-%s", grant.role, grant.database) => grant }

  _schema_grants = flatten([
    for role in local._roles_with_passwords : [
      for grant in coalesce(role.schema_grants, []) : merge(grant, { role = coalesce(grant.role, role.name) })
    ]
  ])
  schema_grants_map = { for grant in local._schema_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  _sequence_grants = flatten([
    for role in local._roles_with_passwords : [
      for grant in coalesce(role.sequence_grants, []) : merge(grant, { role = coalesce(grant.role, role.name) })
    ]
  ])
  sequence_grants_map = { for grant in local._sequence_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  _table_grants = flatten([
    for role in local._roles_with_passwords : [
      for grant in coalesce(role.table_grants, []) : merge(grant, { role = coalesce(grant.role, role.name) })
    ]
  ])
  table_grants_map = { for grant in local._table_grants : format("%s-%s-%s", grant.role, grant.schema, grant.database) => grant }

  databases_map = { for database in var.databases : database.name => database }

  # Built-in PostgreSQL roles that don't need to be created by this module
  builtin_roles = [
    "pg_monitor",
    "pg_read_all_data",
    "pg_write_all_data",
    "pg_read_all_settings",
    "pg_read_all_stats",
    "pg_stat_scan_tables", "pg_signal_backend", "pg_read_server_files",
    "pg_write_server_files", "pg_execute_server_program", "pg_checkpoint", "pg_maintain",
    "pg_create_subscription", "pg_use_reserved_connections"
  ]

  # All custom role names being created by this module
  custom_role_names = [for role in local._roles_with_passwords : role.name]

  # Base roles: no `roles` attribute, or only referencing built-in PostgreSQL roles
  base_roles_map = {
    for role in local._roles_with_passwords : role.name => role
    if try(role.roles, null) == null || alltrue([for r in coalesce(role.roles, []) : contains(local.builtin_roles, r)])
  }

  # Dependent roles: roles that reference other custom roles defined in this module
  dependent_roles_map = {
    for role in local._roles_with_passwords : role.name => role
    if try(role.roles, null) != null && anytrue([for r in coalesce(role.roles, []) : contains(local.custom_role_names, r)])
  }
}

resource "random_password" "user_password" {
  # If no password passed in, then use this to generate one
  count = length(var.roles)

  length = 33
  # Leave special characters out to avoid quoting and other issues.
  # Special characters have no additional security compared to increasing length.
  special          = false
  override_special = "!#$%^&*()<>-_"
}

resource "postgresql_database" "logical_dbs" {
  for_each = local.databases_map

  name             = each.value.name
  connection_limit = each.value.connection_limit
}

# Base roles: roles with no dependencies on other custom roles (created first)
resource "postgresql_role" "base_role" {
  for_each = local.base_roles_map

  name                      = each.value.name
  superuser                 = each.value.superuser
  create_database           = each.value.create_database
  create_role               = each.value.create_role
  inherit                   = each.value.inherit
  login                     = each.value.login
  replication               = each.value.replication
  bypass_row_level_security = each.value.bypass_row_level_security
  connection_limit          = each.value.connection_limit
  encrypted_password        = each.value.encrypted_password
  password                  = each.value.password
  roles                     = each.value.roles
  search_path               = each.value.search_path
  valid_until               = each.value.valid_until
  skip_drop_role            = each.value.skip_drop_role
  skip_reassign_owned       = each.value.skip_reassign_owned
  statement_timeout         = each.value.statement_timeout
  assume_role               = each.value.assume_role

  depends_on = [postgresql_database.logical_dbs]
}

# Dependent roles: roles that inherit from other custom roles (created after base roles)
resource "postgresql_role" "dependent_role" {
  for_each = local.dependent_roles_map

  name                      = each.value.name
  superuser                 = each.value.superuser
  create_database           = each.value.create_database
  create_role               = each.value.create_role
  inherit                   = each.value.inherit
  login                     = each.value.login
  replication               = each.value.replication
  bypass_row_level_security = each.value.bypass_row_level_security
  connection_limit          = each.value.connection_limit
  encrypted_password        = each.value.encrypted_password
  password                  = each.value.password
  roles                     = each.value.roles
  search_path               = each.value.search_path
  valid_until               = each.value.valid_until
  skip_drop_role            = each.value.skip_drop_role
  skip_reassign_owned       = each.value.skip_reassign_owned
  statement_timeout         = each.value.statement_timeout
  assume_role               = each.value.assume_role

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role]
}

resource "postgresql_default_privileges" "privileges" {
  # Postgres documentation specific to default privileges
  # https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html

  for_each = local.default_privileges_map

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  owner       = each.value.owner
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role, postgresql_role.dependent_role]
}

resource "postgresql_grant" "database_access" {
  for_each = local.database_grants_map

  role        = each.value.role
  database    = each.value.database
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role, postgresql_role.dependent_role]
}

resource "postgresql_grant" "schema_access" {
  for_each = local.schema_grants_map

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role, postgresql_role.dependent_role]
}

resource "postgresql_grant" "table_access" {
  for_each = local.table_grants_map

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges
  objects     = try(each.value.objects, null)

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role, postgresql_role.dependent_role]
}

resource "postgresql_grant" "sequence_access" {
  for_each = local.sequence_grants_map

  role        = each.value.role
  database    = each.value.database
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges
  objects     = try(each.value.objects, null)

  depends_on = [postgresql_database.logical_dbs, postgresql_role.base_role, postgresql_role.dependent_role]
}


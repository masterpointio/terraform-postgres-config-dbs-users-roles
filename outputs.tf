output "databases" {
  value = postgresql_database.logical_dbs
}

output "roles" {
  description = "All created roles (both base and dependent)"
  value       = merge(postgresql_role.base_role, postgresql_role.dependent_role)
  sensitive   = true
}

output "base_roles" {
  description = "Base roles (group roles, no dependencies on other custom roles)"
  value       = postgresql_role.base_role
  sensitive   = true
}

output "dependent_roles" {
  description = "Dependent roles (login roles that inherit from other custom roles)"
  value       = postgresql_role.dependent_role
  sensitive   = true
}

output "database_access" {
  value = postgresql_grant.database_access
}

output "schema_access" {
  value = postgresql_grant.schema_access
}

output "table_access" {
  value = postgresql_grant.table_access
}

output "sequence_access" {
  value = postgresql_grant.sequence_access
}

output "default_privileges" {
  value = postgresql_default_privileges.privileges
}

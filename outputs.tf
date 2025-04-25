output "databases" {
  value = postgresql_database.logical_dbs
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

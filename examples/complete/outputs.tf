output "databases" {
  value = module.app_dbs.databases
}

output "database_access" {
  value = module.app_dbs.database_access
}

output "default_privileges" {
  value = module.app_dbs.default_privileges
}

output "schema_access" {
  value = module.app_dbs.schema_access
}

output "table_access" {
  value = module.app_dbs.table_access
}

output "databases" {
  value = module.postgres_automation.databases
}

output "database_access" {
  value = module.postgres_automation.database_access
}

output "default_privileges" {
  value = module.postgres_automation.default_privileges
}

output "schema_access" {
  value = module.postgres_automation.schema_access
}

output "table_access" {
  value = module.postgres_automation.table_access
}

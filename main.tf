resource "postgresql_database" "logical_db" {
  for_each         = { for database in var.databases : database.name => database }
  name             = each.key
  connection_limit = each.value.connection_limit
}

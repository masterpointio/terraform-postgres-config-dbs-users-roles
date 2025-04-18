output "logical_dbs" {
  value = {
    for db in postgresql_database.logical_db : db.name => {
      name             = db.name
      connection_limit = db.connection_limit
    }
  }
}

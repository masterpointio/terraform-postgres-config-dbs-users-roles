# complete/outputs.tf

output "logical_dbs" {
  value = {
    for db in module.app_dbs.logical_dbs : db.name => {
      name             = db.name
      connection_limit = db.connection_limit
    }
  }
}

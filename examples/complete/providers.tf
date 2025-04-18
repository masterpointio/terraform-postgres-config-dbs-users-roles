# complete/providers.tf

provider "postgresql" {
  scheme    = "postgres" # awspostgres does not work with sslmode=disable
  host      = var.db_hostname
  username  = var.db_username
  port      = var.db_port
  password  = var.db_password
  superuser = false
  sslmode   = "disable"
}

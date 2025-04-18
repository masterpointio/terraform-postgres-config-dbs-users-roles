# complete/providers.tf

provider "postgresql" {
  scheme    = var.db_scheme
  host      = var.db_hostname
  username  = var.db_username
  port      = var.db_port
  password  = var.db_password
  superuser = var.db_superuser
  sslmode   = var.db_sslmode
}

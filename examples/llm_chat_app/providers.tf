# llm_chat_app/providers.tf

provider "postgresql" {
  scheme    = local.config.connection.scheme
  host      = local.config.connection.hostname
  username  = local.config.connection.username
  port      = local.config.connection.port
  password  = local.config.connection.password
  superuser = local.config.connection.superuser
  sslmode   = local.config.connection.sslmode
}

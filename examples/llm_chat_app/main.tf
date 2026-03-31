# llm_chat_app/main.tf

# ========================================
# Database (managed here so schemas can depend on it before the module runs)
# ========================================

resource "postgresql_database" "databases" {
  for_each         = { for db in var.databases : db.name => db }
  name             = each.value.name
  connection_limit = each.value.connection_limit
}

# ========================================
# Schemas (created after database, before module)
# ========================================

resource "postgresql_schema" "app" {
  name     = "app"
  database = "llm_service"

  depends_on = [postgresql_database.databases]
}

resource "postgresql_schema" "ref_data_pipeline_abc" {
  name     = "ref_data_pipeline_abc"
  database = "llm_service"

  depends_on = [postgresql_database.databases]
}

resource "postgresql_schema" "ref_data_pipeline_xyz" {
  name     = "ref_data_pipeline_xyz"
  database = "llm_service"

  depends_on = [postgresql_database.databases]
}

# ========================================
# Main module - creates roles and all grants
# databases = [] since the DB is managed above
# depends_on ensures schemas exist before inline schema/table/sequence grants run
# ========================================

module "postgres_automation" {
  source = "../../"

  databases = []
  roles     = var.roles

  depends_on = [
    postgresql_database.databases,
    postgresql_schema.app,
    postgresql_schema.ref_data_pipeline_abc,
    postgresql_schema.ref_data_pipeline_xyz,
  ]
}

# ========================================
# Security: Revoke PUBLIC privileges
# ========================================

resource "postgresql_grant" "revoke_public_connect" {
  database    = "llm_service"
  role        = "public"
  object_type = "database"
  privileges  = []

  depends_on = [module.postgres_automation]
}

resource "postgresql_grant" "revoke_public_schema" {
  database    = "llm_service"
  role        = "public"
  schema      = "public"
  object_type = "schema"
  privileges  = []

  depends_on = [module.postgres_automation]
}

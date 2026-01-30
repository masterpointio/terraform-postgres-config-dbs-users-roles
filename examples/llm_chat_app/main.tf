# llm_chat_app/main.tf

module "postgres_automation" {
  source = "../../"

  databases = var.databases
  roles     = var.roles
}

# Create schemas with migration role as owner
resource "postgresql_schema" "app" {
  name     = "app"
  database = "llm_service"
  owner    = "role_service_migration"

  depends_on = [module.postgres_automation]
}

resource "postgresql_schema" "ref_data_pipeline_abc" {
  name     = "ref_data_pipeline_abc"
  database = "llm_service"
  owner    = "role_service_migration"

  depends_on = [module.postgres_automation]
}

resource "postgresql_schema" "ref_data_pipeline_xyz" {
  name     = "ref_data_pipeline_xyz"
  database = "llm_service"
  owner    = "role_service_migration"

  depends_on = [module.postgres_automation]
}

# ========================================
# RW Group Role - App Schema Grants
# ========================================
# These grants must be in main.tf because they depend on schema creation

resource "postgresql_grant" "rw_app_schema" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "rw_app_tables" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "rw_app_sequences" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "rw_app_tables" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "rw_app_sequences" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "rw_app_functions" {
  database    = "llm_service"
  role        = "role_service_rw"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

# ========================================
# RO Group Role - App Schema Grants
# ========================================

resource "postgresql_grant" "ro_app_schema" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "ro_app_tables" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "ro_app_sequences" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "ro_app_tables" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "ro_app_sequences" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_default_privileges" "ro_app_functions" {
  database    = "llm_service"
  role        = "role_service_ro"
  schema      = "app"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

# ========================================
# Revoke PUBLIC Privileges
# ========================================

# Revoke PUBLIC privileges on database
# This prevents any authenticated cluster user from connecting
resource "postgresql_grant" "revoke_public_connect" {
  database    = "llm_service"
  role        = "public"
  object_type = "database"
  privileges  = []

  depends_on = [module.postgres_automation]
}

# Revoke PUBLIC privileges on public schema
resource "postgresql_grant" "revoke_public_schema" {
  database    = "llm_service"
  role        = "public"
  schema      = "public"
  object_type = "schema"
  privileges  = []

  depends_on = [module.postgres_automation]
}

# ========================================
# Migration Role - Additional Schema Grants
# ========================================
# Note: Migration role owns all schemas (set via postgresql_schema.owner above)
# These grants provide the necessary privileges for DDL operations

# App schema grants for migration role
resource "postgresql_grant" "migration_app_schema" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "app"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "migration_app_tables" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "app"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

resource "postgresql_grant" "migration_app_sequences" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "app"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.app]
}

# ref_data_pipeline_abc schema grants for migration role
resource "postgresql_grant" "migration_abc_schema" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_abc"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "migration_abc_tables" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_abc"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "migration_abc_sequences" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_abc"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

# ref_data_pipeline_xyz schema grants for migration role
resource "postgresql_grant" "migration_xyz_schema" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_xyz"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "migration_xyz_tables" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_xyz"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "migration_xyz_sequences" {
  database    = "llm_service"
  role        = "role_service_migration"
  schema      = "ref_data_pipeline_xyz"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

# ========================================
# Pipeline RW Login Role - ref_data Schema Grants
# ========================================
# Note: service_pipeline_rw inherits app schema access from role_service_rw
# These grants provide additional access to ref_data schemas

resource "postgresql_grant" "pipeline_rw_abc_schema" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_rw_abc_tables" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_rw_abc_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_rw_xyz_schema" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "pipeline_rw_xyz_tables" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "pipeline_rw_xyz_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

# ========================================
# Pipeline RO Login Role - ref_data Schema Grants
# ========================================
# Note: service_pipeline_ro inherits app schema access from role_service_ro
# These grants provide additional access to ref_data schemas

resource "postgresql_grant" "pipeline_ro_abc_schema" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_ro_abc_tables" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_ro_abc_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_grant" "pipeline_ro_xyz_schema" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "pipeline_ro_xyz_tables" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_grant" "pipeline_ro_xyz_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

# ========================================
# Default Privileges for ref_data Schemas
# ========================================
# These ensure new objects created by migration role automatically grant access to pipeline roles

# ref_data_pipeline_abc - pipeline_rw
resource "postgresql_default_privileges" "pipeline_rw_abc_tables" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_default_privileges" "pipeline_rw_abc_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_default_privileges" "pipeline_rw_abc_functions" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

# ref_data_pipeline_abc - pipeline_ro
resource "postgresql_default_privileges" "pipeline_ro_abc_tables" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_default_privileges" "pipeline_ro_abc_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

resource "postgresql_default_privileges" "pipeline_ro_abc_functions" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_abc"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_abc]
}

# ref_data_pipeline_xyz - pipeline_rw
resource "postgresql_default_privileges" "pipeline_rw_xyz_tables" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_default_privileges" "pipeline_rw_xyz_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_default_privileges" "pipeline_rw_xyz_functions" {
  database    = "llm_service"
  role        = "service_pipeline_rw"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

# ref_data_pipeline_xyz - pipeline_ro
resource "postgresql_default_privileges" "pipeline_ro_xyz_tables" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "table"
  privileges  = ["SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_default_privileges" "pipeline_ro_xyz_sequences" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

resource "postgresql_default_privileges" "pipeline_ro_xyz_functions" {
  database    = "llm_service"
  role        = "service_pipeline_ro"
  schema      = "ref_data_pipeline_xyz"
  owner       = "role_service_migration"
  object_type = "function"
  privileges  = ["EXECUTE"]

  depends_on = [module.postgres_automation, postgresql_schema.ref_data_pipeline_xyz]
}

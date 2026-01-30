# llm_chat_app/fixtures.auto.tfvars

# PostgreSQL connection settings
# postgres shell commands to create this user:
# CREATE ROLE admin_user LOGIN CREATEROLE PASSWORD 'insecure-pass-for-demo-admin-user';
# GRANT pg_monitor TO admin_user WITH ADMIN OPTION;
db_username  = "admin_user"
db_password  = "insecure-pass-for-demo-admin-user"
db_scheme    = "postgres"
db_hostname  = "localhost"
db_port      = 5432
db_superuser = false
db_sslmode   = "disable"

# Database configuration
databases = [
  {
    name             = "llm_service"
    connection_limit = 100
  }
]

# Role configuration
roles = [
  # ========================================
  # Cluster-wide roles
  # ========================================

  # Cluster admin role - manages users/roles across all databases
  {
    role = {
      name            = "role_pg_cluster_admin"
      login           = true
      inherit         = true
      create_role     = true
      create_database = false
      password        = "demo-password-cluster-admin"
    }
  },

  # Monitoring role - read-only access to system statistics
  {
    role = {
      name     = "role_pg_monitoring"
      login    = true
      inherit  = true
      roles    = ["pg_monitor"]
      password = "demo-password-monitoring"
    }
  },

  # ========================================
  # Service-scoped roles (llm_service)
  # ========================================

  # Migration group role - owns database, schemas, and all objects (no login)
  {
    role = {
      name            = "role_service_migration"
      login           = false # group role, no login
      inherit         = true
      create_role     = false
      create_database = false
    }
    database_grants = {
      role        = "role_service_migration"
      database    = "llm_service"
      object_type = "database"
      privileges  = ["CREATE", "CONNECT", "TEMPORARY"]
    }
  },

  # Migration login role - inherits from migration group
  {
    role = {
      name             = "service_migrator"
      login            = true
      inherit          = true
      roles            = ["role_service_migration"]
      connection_limit = 5
      password         = "demo-password-migrator"
    }
  },

  # ========================================
  # Group roles (no login)
  # ========================================

  # RW group role - read/write permissions on app schema
  # Note: Schema-specific grants are in main.tf (depends on schema creation)
  {
    role = {
      name    = "role_service_rw"
      login   = false
      inherit = true
    }
    database_grants = {
      role        = "role_service_rw"
      database    = "llm_service"
      object_type = "database"
      privileges  = ["CONNECT"]
    }
  },

  # RO group role - read-only permissions on app schema
  # Note: Schema-specific grants are in main.tf (depends on schema creation)
  {
    role = {
      name    = "role_service_ro"
      login   = false
      inherit = true
    }
    database_grants = {
      role        = "role_service_ro"
      database    = "llm_service"
      object_type = "database"
      privileges  = ["CONNECT"]
    }
  },

  # ========================================
  # Login roles (Application Processes)
  # ========================================

  # FastAPI backend - read/write
  {
    role = {
      name             = "service_fastapi_rw"
      login            = true
      inherit          = true
      roles            = ["role_service_rw"]
      connection_limit = 30
      password         = "demo-password-fastapi-rw"
    }
  },

  # FastAPI backend - read-only
  {
    role = {
      name             = "service_fastapi_ro"
      login            = true
      inherit          = true
      roles            = ["role_service_ro"]
      connection_limit = 30
      password         = "demo-password-fastapi-ro"
    }
  },

  # Data pipeline - read/write (inherits app access, ref_data grants in main.tf)
  {
    role = {
      name             = "service_pipeline_rw"
      login            = true
      inherit          = true
      roles            = ["role_service_rw"]
      connection_limit = 10
      password         = "demo-password-pipeline-rw"
    }
  },

  # Data pipeline - read-only (inherits app access, ref_data grants in main.tf)
  {
    role = {
      name             = "service_pipeline_ro"
      login            = true
      inherit          = true
      roles            = ["role_service_ro"]
      connection_limit = 10
      password         = "demo-password-pipeline-ro"
    }
  }
]

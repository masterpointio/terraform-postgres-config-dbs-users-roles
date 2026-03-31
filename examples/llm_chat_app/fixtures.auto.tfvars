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
  # Migration group role - owns all schemas and DDL
  # ========================================

  {
    role = {
      name    = "role_service_migration"
      login   = false
      inherit = true
    }
    database_grants = {
      role        = "role_service_migration"
      database    = "llm_service"
      object_type = "database"
      privileges  = ["CREATE", "CONNECT", "TEMPORARY"]
    }
    schema_grants = [
      { role = "role_service_migration", database = "llm_service", schema = "app", object_type = "schema", privileges = ["USAGE", "CREATE"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "schema", privileges = ["USAGE", "CREATE"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "schema", privileges = ["USAGE", "CREATE"] },
    ]
    table_grants = [
      { role = "role_service_migration", database = "llm_service", schema = "app", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES"] },
    ]
    sequence_grants = [
      { role = "role_service_migration", database = "llm_service", schema = "app", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "role_service_migration", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
    ]
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
  # RW group role - read/write on app schema
  # ========================================

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
    schema_grants = [
      { role = "role_service_rw", database = "llm_service", schema = "app", object_type = "schema", privileges = ["USAGE"] },
    ]
    table_grants = [
      { role = "role_service_rw", database = "llm_service", schema = "app", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"] },
    ]
    sequence_grants = [
      { role = "role_service_rw", database = "llm_service", schema = "app", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
    ]
    default_privileges = [
      { role = "role_service_rw", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE"] },
      { role = "role_service_rw", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "role_service_rw", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
    ]
  },

  # ========================================
  # RO group role - read-only on app schema
  # ========================================

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
    schema_grants = [
      { role = "role_service_ro", database = "llm_service", schema = "app", object_type = "schema", privileges = ["USAGE"] },
    ]
    table_grants = [
      { role = "role_service_ro", database = "llm_service", schema = "app", object_type = "table", privileges = ["SELECT"] },
    ]
    sequence_grants = [
      { role = "role_service_ro", database = "llm_service", schema = "app", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
    ]
    default_privileges = [
      { role = "role_service_ro", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "table", privileges = ["SELECT"] },
      { role = "role_service_ro", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
      { role = "role_service_ro", database = "llm_service", schema = "app", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
    ]
  },

  # ========================================
  # Login roles - app schema (inherit from rw/ro)
  # ========================================

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

  # ========================================
  # Pipeline login roles - ref_data schemas + inherited app access
  # ========================================

  {
    role = {
      name             = "service_pipeline_rw"
      login            = true
      inherit          = true
      roles            = ["role_service_rw"]
      connection_limit = 10
      password         = "demo-password-pipeline-rw"
    }
    schema_grants = [
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "schema", privileges = ["USAGE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "schema", privileges = ["USAGE"] },
    ]
    table_grants = [
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"] },
    ]
    sequence_grants = [
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
    ]
    default_privileges = [
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "table", privileges = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT", "UPDATE"] },
      { role = "service_pipeline_rw", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
    ]
  },

  {
    role = {
      name             = "service_pipeline_ro"
      login            = true
      inherit          = true
      roles            = ["role_service_ro"]
      connection_limit = 10
      password         = "demo-password-pipeline-ro"
    }
    schema_grants = [
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "schema", privileges = ["USAGE"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "schema", privileges = ["USAGE"] },
    ]
    table_grants = [
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "table", privileges = ["SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "table", privileges = ["SELECT"] },
    ]
    sequence_grants = [
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
    ]
    default_privileges = [
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "table", privileges = ["SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_abc", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "table", privileges = ["SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "sequence", privileges = ["USAGE", "SELECT"] },
      { role = "service_pipeline_ro", database = "llm_service", schema = "ref_data_pipeline_xyz", owner = "role_service_migration", object_type = "function", privileges = ["EXECUTE"] },
    ]
  },
]

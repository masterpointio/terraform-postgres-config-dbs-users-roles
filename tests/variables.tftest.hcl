mock_provider "postgresql" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test: Default values work correctly
# -----------------------------------------------------------------------------

run "default_values" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  # Use only default values
  variables {
    # databases and roles default to []
  }

  assert {
    condition     = length(var.databases) == 0
    error_message = "databases should default to empty list"
  }

  assert {
    condition     = length(var.roles) == 0
    error_message = "roles should default to empty list"
  }
}

# -----------------------------------------------------------------------------
# Test: Database variable accepts optional connection_limit
# -----------------------------------------------------------------------------

run "database_optional_connection_limit" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [
      {
        name = "db_with_limit"
        connection_limit = 100
      },
      {
        name = "db_without_limit"
      }
    ]
    roles = []
  }

  assert {
    condition     = var.databases[0].connection_limit == 100
    error_message = "Database with connection_limit should preserve value"
  }

  assert {
    condition     = var.databases[1].connection_limit == null
    error_message = "Database without connection_limit should be null"
  }
}

# -----------------------------------------------------------------------------
# Test: Role variable accepts all optional attributes
# -----------------------------------------------------------------------------

run "role_accepts_all_attributes" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name                      = "full_featured_role"
        superuser                 = true
        create_database           = true
        create_role               = true
        inherit                   = false
        login                     = true
        replication               = false
        bypass_row_level_security = true
        connection_limit          = 50
        encrypted_password        = true
        password                  = "secret123"
        roles                     = ["pg_monitor"]
        search_path               = ["public", "app"]
        valid_until               = "2025-12-31"
        skip_drop_role            = true
        skip_reassign_owned       = false
        statement_timeout         = 10000
        assume_role               = "admin"
      }
    }]
  }

  assert {
    condition     = var.roles[0].role.name == "full_featured_role"
    error_message = "Role name should be set"
  }

  assert {
    condition     = var.roles[0].role.superuser == true
    error_message = "Role superuser should be set"
  }

  assert {
    condition     = var.roles[0].role.connection_limit == 50
    error_message = "Role connection_limit should be set"
  }
}

# -----------------------------------------------------------------------------
# Test: Role with grants
# -----------------------------------------------------------------------------

run "role_with_all_grant_types" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name = "test_db"
    }]
    roles = [{
      role = {
        name = "granted_role"
      }
      database_grants = {
        role        = "granted_role"
        database    = "test_db"
        object_type = "database"
        privileges  = ["CONNECT", "TEMPORARY"]
      }
      schema_grants = {
        role        = "granted_role"
        database    = "test_db"
        schema      = "public"
        object_type = "schema"
        privileges  = ["USAGE", "CREATE"]
      }
      table_grants = {
        role        = "granted_role"
        database    = "test_db"
        schema      = "public"
        object_type = "table"
        objects     = ["table1", "table2"]
        privileges  = ["SELECT", "INSERT"]
      }
      sequence_grants = {
        role        = "granted_role"
        database    = "test_db"
        schema      = "public"
        object_type = "sequence"
        objects     = []
        privileges  = ["USAGE", "SELECT"]
      }
      default_privileges = [
        {
          role        = "granted_role"
          database    = "test_db"
          schema      = "public"
          owner       = "admin"
          object_type = "table"
          privileges  = ["SELECT"]
        }
      ]
    }]
  }

  assert {
    condition     = var.roles[0].database_grants.role == "granted_role"
    error_message = "Database grants should be set"
  }

  assert {
    condition     = length(var.roles[0].default_privileges) == 1
    error_message = "Default privileges should be set"
  }
}

# -----------------------------------------------------------------------------
# Test: Minimal role configuration
# -----------------------------------------------------------------------------

run "minimal_role_configuration" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name = "minimal_role"
      }
    }]
  }

  assert {
    condition     = var.roles[0].role.name == "minimal_role"
    error_message = "Minimal role should only need name"
  }

  assert {
    condition     = var.roles[0].database_grants == null
    error_message = "Grants should be null by default"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple databases
# -----------------------------------------------------------------------------

run "multiple_databases" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [
      { name = "db1", connection_limit = 10 },
      { name = "db2", connection_limit = 20 },
      { name = "db3", connection_limit = 30 }
    ]
    roles = []
  }

  assert {
    condition     = length(var.databases) == 3
    error_message = "Should accept multiple databases"
  }

  assert {
    condition     = var.databases[0].name == "db1"
    error_message = "First database should be db1"
  }

  assert {
    condition     = var.databases[2].connection_limit == 30
    error_message = "Third database should have connection_limit 30"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple roles with different configurations
# -----------------------------------------------------------------------------

run "multiple_roles_different_configs" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name  = "group_role"
          login = false
        }
      },
      {
        role = {
          name     = "login_role"
          login    = true
          password = "pass123"
        }
      },
      {
        role = {
          name  = "inherited_role"
          login = true
          roles = ["group_role"]
        }
      }
    ]
  }

  assert {
    condition     = length(var.roles) == 3
    error_message = "Should accept multiple roles"
  }

  assert {
    condition     = var.roles[0].role.login == false
    error_message = "First role should be non-login group role"
  }

  assert {
    condition     = var.roles[1].role.password == "pass123"
    error_message = "Second role should have password"
  }

  assert {
    condition     = contains(var.roles[2].role.roles, "group_role")
    error_message = "Third role should inherit from group_role"
  }
}

# -----------------------------------------------------------------------------
# Test: Empty objects list in grants
# -----------------------------------------------------------------------------

run "empty_objects_list_in_grants" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{ name = "db1" }]
    roles = [{
      role = {
        name = "test_role"
      }
      table_grants = {
        role        = "test_role"
        database    = "db1"
        schema      = "public"
        object_type = "table"
        objects     = []  # Empty means all tables
        privileges  = ["SELECT"]
      }
    }]
  }

  assert {
    condition     = length(var.roles[0].table_grants.objects) == 0
    error_message = "Empty objects list should be valid (grants to all)"
  }
}

# -----------------------------------------------------------------------------
# Test: Specific objects list in grants
# -----------------------------------------------------------------------------

run "specific_objects_in_grants" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{ name = "db1" }]
    roles = [{
      role = {
        name = "test_role"
      }
      table_grants = {
        role        = "test_role"
        database    = "db1"
        schema      = "public"
        object_type = "table"
        objects     = ["users", "orders", "products"]
        privileges  = ["SELECT"]
      }
    }]
  }

  assert {
    condition     = length(var.roles[0].table_grants.objects) == 3
    error_message = "Should accept specific objects list"
  }

  assert {
    condition     = contains(var.roles[0].table_grants.objects, "users")
    error_message = "Objects list should contain 'users'"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple privileges
# -----------------------------------------------------------------------------

run "multiple_privileges" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{ name = "db1" }]
    roles = [{
      role = {
        name = "test_role"
      }
      table_grants = {
        role        = "test_role"
        database    = "db1"
        schema      = "public"
        object_type = "table"
        objects     = []
        privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
      }
    }]
  }

  assert {
    condition     = length(var.roles[0].table_grants.privileges) == 4
    error_message = "Should accept multiple privileges"
  }
}

# -----------------------------------------------------------------------------
# Test: Connection limit of -1 (unlimited)
# -----------------------------------------------------------------------------

run "unlimited_connection_limit" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name             = "unlimited_db"
      connection_limit = -1
    }]
    roles = [{
      role = {
        name             = "unlimited_role"
        connection_limit = -1
      }
    }]
  }

  assert {
    condition     = var.databases[0].connection_limit == -1
    error_message = "Database should accept -1 as unlimited"
  }

  assert {
    condition     = var.roles[0].role.connection_limit == -1
    error_message = "Role should accept -1 as unlimited"
  }
}
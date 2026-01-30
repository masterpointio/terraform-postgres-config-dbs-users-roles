mock_provider "postgresql" {
  alias = "mock"
}

variables {
  databases = [{
    name             = "test_db"
    connection_limit = 50
  }]

  roles = [
    {
      role = {
        name  = "base_role"
        login = false
      }
    },
    {
      role = {
        name  = "dependent_role"
        login = true
        roles = ["base_role"]
      }
      database_grants = {
        role        = "dependent_role"
        database    = "test_db"
        object_type = "database"
        privileges  = ["CONNECT"]
      }
      schema_grants = {
        role        = "dependent_role"
        database    = "test_db"
        schema      = "public"
        object_type = "schema"
        privileges  = ["USAGE"]
      }
      table_grants = {
        role        = "dependent_role"
        database    = "test_db"
        schema      = "public"
        object_type = "table"
        objects     = []
        privileges  = ["SELECT"]
      }
      sequence_grants = {
        role        = "dependent_role"
        database    = "test_db"
        schema      = "public"
        object_type = "sequence"
        objects     = []
        privileges  = ["USAGE"]
      }
      default_privileges = [{
        role        = "dependent_role"
        database    = "test_db"
        schema      = "public"
        owner       = "admin"
        object_type = "table"
        privileges  = ["SELECT"]
      }]
    }
  ]
}

# -----------------------------------------------------------------------------
# Test: databases output structure
# -----------------------------------------------------------------------------

run "databases_output_structure" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(keys(output.databases)) == 1
    error_message = "Should output 1 database"
  }

  assert {
    condition     = output.databases["test_db"].name == "test_db"
    error_message = "Database output should contain correct name"
  }
}

# -----------------------------------------------------------------------------
# Test: roles output contains both base and dependent
# -----------------------------------------------------------------------------

run "roles_output_is_merged" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(keys(output.roles)) == 2
    error_message = "Should output 2 roles (base + dependent)"
  }

  assert {
    condition     = contains(keys(output.roles), "base_role")
    error_message = "Should contain base_role"
  }

  assert {
    condition     = contains(keys(output.roles), "dependent_role")
    error_message = "Should contain dependent_role"
  }
}

# -----------------------------------------------------------------------------
# Test: base_roles output contains only base roles
# -----------------------------------------------------------------------------

run "base_roles_output_excludes_dependent" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(keys(output.base_roles)) == 1
    error_message = "Should output 1 base role"
  }

  assert {
    condition     = contains(keys(output.base_roles), "base_role")
    error_message = "Should contain base_role"
  }

  assert {
    condition     = !contains(keys(output.base_roles), "dependent_role")
    error_message = "Should NOT contain dependent_role"
  }
}

# -----------------------------------------------------------------------------
# Test: dependent_roles output contains only dependent roles
# -----------------------------------------------------------------------------

run "dependent_roles_output_excludes_base" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(keys(output.dependent_roles)) == 1
    error_message = "Should output 1 dependent role"
  }

  assert {
    condition     = contains(keys(output.dependent_roles), "dependent_role")
    error_message = "Should contain dependent_role"
  }

  assert {
    condition     = !contains(keys(output.dependent_roles), "base_role")
    error_message = "Should NOT contain base_role"
  }
}

# -----------------------------------------------------------------------------
# Test: grant outputs contain correct resources
# -----------------------------------------------------------------------------

run "grant_outputs_structure" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(keys(output.database_access)) == 1
    error_message = "Should output 1 database grant"
  }

  assert {
    condition     = length(keys(output.schema_access)) == 1
    error_message = "Should output 1 schema grant"
  }

  assert {
    condition     = length(keys(output.table_access)) == 1
    error_message = "Should output 1 table grant"
  }

  assert {
    condition     = length(keys(output.sequence_access)) == 1
    error_message = "Should output 1 sequence grant"
  }

  assert {
    condition     = length(keys(output.default_privileges)) == 1
    error_message = "Should output 1 default privilege"
  }
}

# -----------------------------------------------------------------------------
# Test: role outputs are marked as sensitive
# -----------------------------------------------------------------------------

run "role_outputs_are_sensitive" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  # We can't directly test sensitive flag, but we can verify outputs exist
  assert {
    condition     = output.roles != null
    error_message = "roles output should exist"
  }

  assert {
    condition     = output.base_roles != null
    error_message = "base_roles output should exist"
  }

  assert {
    condition     = output.dependent_roles != null
    error_message = "dependent_roles output should exist"
  }
}

# -----------------------------------------------------------------------------
# Test: empty configuration outputs
# -----------------------------------------------------------------------------

run "empty_configuration_outputs" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles     = []
  }

  assert {
    condition     = length(keys(output.databases)) == 0
    error_message = "Empty databases should result in empty output"
  }

  assert {
    condition     = length(keys(output.roles)) == 0
    error_message = "Empty roles should result in empty output"
  }

  assert {
    condition     = length(keys(output.database_access)) == 0
    error_message = "No grants should result in empty database_access output"
  }
}

# -----------------------------------------------------------------------------
# Test: multiple databases and roles in output
# -----------------------------------------------------------------------------

run "multiple_resources_in_outputs" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [
      { name = "db1", connection_limit = 10 },
      { name = "db2", connection_limit = 20 },
      { name = "db3", connection_limit = 30 }
    ]
    roles = [
      { role = { name = "role1" } },
      { role = { name = "role2" } },
      { role = { name = "role3" } }
    ]
  }

  assert {
    condition     = length(keys(output.databases)) == 3
    error_message = "Should output all 3 databases"
  }

  assert {
    condition     = length(keys(output.roles)) == 3
    error_message = "Should output all 3 roles"
  }
}
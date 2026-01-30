mock_provider "postgresql" {
  alias = "mock"
}

variables {
    databases = [{
        name = "app"
        connection_limit = 10
    }, {
        name = "app2"
    }]

    roles = [{
        role = {
            name = "app_user"
            password = "app_user_password"
        }
        default_privileges = [
          {
            role = "app_user"
            database = "app"
            owner = "app_user"
            schema = "public"
            object_type = "schema"
            privileges = ["ALL"]
          },
          {
            role = "app_user"
            database = "app"
            owner = "app_user"
            schema = "public"
            object_type = "table"
            objects = []
            privileges = ["ALL"]
          },
          {
            role = "app_user"
            database = "app"
            owner = "app_user"
            schema = "public"
            object_type = "sequence"
            objects = []
            privileges = ["ALL"]
          }
        ]
        database_grants = {
            role = "app_user"
            database = "app2"
            object_type = "database"
            privileges = ["CONNECT"]
        }
        schema_grants = {
          role        = "app_user"
          database    = "app2"
          schema      = "public"
          object_type = "schema"
          objects     = ["public"]
          privileges  = ["USAGE"]
        }
        sequence_grants = {
            role        = "app_user"
            database    = "app2"
            schema      = "public"
            object_type = "sequence"
            objects     = [] # all sequences
            privileges  = ["USAGE", "SELECT"]
        }
        table_grants = {
            role        = "app_user"
            database    = "app2"
            schema      = "public"
            object_type = "table"
            objects     = [] # all tables
            privileges  = ["SELECT"]
        }
    }, {
        role = {
            name = "app_user2"
        }
    }]
}

# -----------------------------------------------------------------------------
# --- validate local values 
# -----------------------------------------------------------------------------

run "validate_local_default_privileges" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = local.default_privileges_map["app_user-app-public-schema"].role == "app_user"
    error_message = "Check intermediate local values"
  }
}


run "validate_local_database_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = local.database_grants_map["app_user-app2"].role == "app_user"
    error_message = "Check intermediate local values"
  }
}

run "validate_local_schema_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = local.schema_grants_map["app_user-public-app2"].role == "app_user"
    error_message = "Check intermediate local values"
  }
}

run "validate_local_sequence_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = local.sequence_grants_map["app_user-public-app2"].role == "app_user"
    error_message = "Check intermediate local values"
  }
}

run "validate_local_table_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = local.table_grants_map["app_user-public-app2"].role == "app_user"
    error_message = "Check intermediate local values"
  }
}


# -----------------------------------------------------------------------------
# --- validate resources
# -----------------------------------------------------------------------------

run "validate_databases" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_database.logical_dbs["app"].name == "app"
    error_message = "Database should have correct name"
  }

  assert {
    condition     = postgresql_database.logical_dbs["app"].connection_limit == 10
    error_message = "Database should have correct connection limit"
  }

  assert {
    condition     = postgresql_database.logical_dbs["app2"].connection_limit == null
    error_message = "Database should have no connection limit"
  }
}

run "validate_roles_with_password" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_role.base_role["app_user"].password == "app_user_password"
    error_message = "Role should have correct password"
  }
}


run "validate_roles_with_random_password" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(postgresql_role.base_role["app_user2"].password) == 33
    error_message = "Role should have random password"
  }

  assert {
    condition     = alltrue([for c in ["!", "#", "$", "%", "^", "&", "*", "(", ")", "<", ">", "-", "_"] : length(split(c, postgresql_role.base_role["app_user2"].password)) == 1])
    error_message = "Password contains forbidden special characters"
  }
}


run "validate_default_privileges" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }
  assert {
    condition = postgresql_default_privileges.privileges["app_user-app-public-schema"].object_type == "schema"
    error_message = "Check intermediate local values"
  }
}

run "validate_database_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = postgresql_grant.database_access["app_user-app2"].privileges == toset(["CONNECT"])
    error_message = "Check intermediate local values"
  }
}

run "validate_schema_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = postgresql_grant.schema_access["app_user-public-app2"].privileges == toset(["USAGE"])
    error_message = "Check intermediate local values"
  }
}

run "validate_sequence_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = postgresql_grant.sequence_access["app_user-public-app2"].privileges == toset(["USAGE", "SELECT"])
    error_message = "Check intermediate local values"
  }
}

run "validate_table_grants" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition = postgresql_grant.table_access["app_user-public-app2"].privileges == toset(["SELECT"])
    error_message = "Check intermediate local values"
  }
}

# -----------------------------------------------------------------------------
# --- Test edge cases and error conditions
# -----------------------------------------------------------------------------

run "empty_databases_and_roles" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = []
  }

  assert {
    condition = length(local.databases_map) == 0
    error_message = "Empty databases should result in empty map"
  }

  assert {
    condition = length(local.custom_role_names) == 0
    error_message = "Empty roles should result in empty list"
  }
}

run "database_without_connection_limit" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name = "test_db"
    }]
    roles = []
  }

  assert {
    condition = local.databases_map["test_db"].name == "test_db"
    error_message = "Database should be created without connection_limit"
  }
}

run "role_with_all_optional_attributes" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name = "full_role"
        superuser = true
        create_database = true
        create_role = true
        inherit = false
        login = true
        replication = true
        bypass_row_level_security = true
        connection_limit = 10
        encrypted_password = true
        password = "test_pass"
        roles = ["pg_monitor"]
        search_path = ["public", "app"]
        skip_drop_role = true
        skip_reassign_owned = true
        statement_timeout = 5000
      }
    }]
  }

  assert {
    condition = local.base_roles_map["full_role"].role.superuser == true
    error_message = "Role should have all optional attributes set"
  }

  assert {
    condition = local.base_roles_map["full_role"].role.connection_limit == 10
    error_message = "Connection limit should be set correctly"
  }
}

run "multiple_default_privileges_same_role" {
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
        name = "test_user"
      }
      default_privileges = [
        {
          role = "test_user"
          database = "test_db"
          schema = "public"
          owner = "admin"
          object_type = "table"
          privileges = ["SELECT"]
        },
        {
          role = "test_user"
          database = "test_db"
          schema = "public"
          owner = "admin"
          object_type = "sequence"
          privileges = ["USAGE"]
        }
      ]
    }]
  }

  assert {
    condition = length(local.default_privileges_map) == 2
    error_message = "Multiple default privileges should be created"
  }

  assert {
    condition = contains(keys(local.default_privileges_map), "test_user-test_db-public-table")
    error_message = "Table default privileges should exist"
  }

  assert {
    condition = contains(keys(local.default_privileges_map), "test_user-test_db-public-sequence")
    error_message = "Sequence default privileges should exist"
  }
}

run "complex_role_hierarchy" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "base_group"
          login = false
        }
      },
      {
        role = {
          name = "mid_group"
          login = false
          roles = ["pg_read_all_data"]
        }
      },
      {
        role = {
          name = "login_user"
          login = true
          roles = ["base_group", "mid_group"]
        }
      }
    ]
  }

  assert {
    condition = length(local.base_roles_map) == 2
    error_message = "Should have 2 base roles"
  }

  assert {
    condition = length(local.dependent_roles_map) == 1
    error_message = "Should have 1 dependent role"
  }

  assert {
    condition = contains(keys(local.dependent_roles_map), "login_user")
    error_message = "login_user should be dependent role"
  }
}

run "password_generation_for_role_without_password" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name = "auto_password_user"
        login = true
      }
    }]
  }

  assert {
    condition = length(postgresql_role.base_role["auto_password_user"].password) == 33
    error_message = "Random password should be 33 characters long"
  }
}

run "grants_map_key_formats" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name = "db1"
    }]
    roles = [{
      role = {
        name = "test_role"
      }
      database_grants = {
        role = "test_role"
        database = "db1"
        object_type = "database"
        privileges = ["CONNECT"]
      }
      schema_grants = {
        role = "test_role"
        database = "db1"
        schema = "public"
        object_type = "schema"
        privileges = ["USAGE"]
      }
      table_grants = {
        role = "test_role"
        database = "db1"
        schema = "public"
        object_type = "table"
        objects = []
        privileges = ["SELECT"]
      }
      sequence_grants = {
        role = "test_role"
        database = "db1"
        schema = "public"
        object_type = "sequence"
        objects = []
        privileges = ["USAGE"]
      }
    }]
  }

  assert {
    condition = contains(keys(local.database_grants_map), "test_role-db1")
    error_message = "Database grant key should be 'role-database'"
  }

  assert {
    condition = contains(keys(local.schema_grants_map), "test_role-public-db1")
    error_message = "Schema grant key should be 'role-schema-database'"
  }

  assert {
    condition = contains(keys(local.table_grants_map), "test_role-public-db1")
    error_message = "Table grant key should be 'role-schema-database'"
  }

  assert {
    condition = contains(keys(local.sequence_grants_map), "test_role-public-db1")
    error_message = "Sequence grant key should be 'role-schema-database'"
  }
}

run "null_grants_are_filtered_out" {
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
      # No grants specified - all are null
    }]
  }

  assert {
    condition = length(local.database_grants_map) == 0
    error_message = "Null database grants should be filtered out"
  }

  assert {
    condition = length(local.schema_grants_map) == 0
    error_message = "Null schema grants should be filtered out"
  }

  assert {
    condition = length(local.table_grants_map) == 0
    error_message = "Null table grants should be filtered out"
  }

  assert {
    condition = length(local.sequence_grants_map) == 0
    error_message = "Null sequence grants should be filtered out"
  }

  assert {
    condition = length(local.default_privileges_map) == 0
    error_message = "Null default privileges should be filtered out"
  }
}

run "builtin_roles_are_comprehensive" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = []
  }

  assert {
    condition = length(local.builtin_roles) >= 13
    error_message = "Should have at least 13 built-in PostgreSQL roles"
  }

  assert {
    condition = contains(local.builtin_roles, "pg_checkpoint")
    error_message = "Should include pg_checkpoint"
  }

  assert {
    condition = contains(local.builtin_roles, "pg_use_reserved_connections")
    error_message = "Should include pg_use_reserved_connections"
  }
}

run "role_depends_on_database" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name = "dep_test"
    }]
    roles = [{
      role = {
        name = "dependent_role"
      }
    }]
  }

  # Verify resources exist in the plan
  assert {
    condition = length([for r in postgresql_role.base_role : r]) > 0
    error_message = "Base role should be created"
  }
}

run "connection_limit_zero_means_unlimited" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [{
      name = "test_db"
      connection_limit = 0
    }]
    roles = [{
      role = {
        name = "unlimited_user"
        connection_limit = 0
      }
    }]
  }

  assert {
    condition = local.databases_map["test_db"].connection_limit == 0
    error_message = "Database connection limit of 0 should be preserved"
  }

  assert {
    condition = local.base_roles_map["unlimited_user"].role.connection_limit == 0
    error_message = "Role connection limit of 0 should be preserved"
  }
}
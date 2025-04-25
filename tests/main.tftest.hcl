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
    condition     = postgresql_role.role["app_user"].password == "app_user_password"
    error_message = "Role should have correct password"
  } 
}


run "validate_roles_with_random_password" {
  command = apply

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = length(postgresql_role.role["app_user2"].password) == 33
    error_message = "Role should have random password"
  }

  assert {
    condition = alltrue([for c in ["!", "#", "$", "%", "^", "&", "*", "(", ")", "<", ">", "-", "_"] : length(split(c, postgresql_role.role["app_user2"].password)) == 1])
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

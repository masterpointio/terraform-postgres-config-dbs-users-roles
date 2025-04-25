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
    }, {
        role = {
            name = "app_user2"
        }
    }]
}

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
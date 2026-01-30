mock_provider "postgresql" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test: Role with no `roles` attribute should be classified as base role
# -----------------------------------------------------------------------------

run "role_without_roles_attribute_is_base" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name = "standalone_user"
      }
    }]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "standalone_user")
    error_message = "Role without 'roles' attribute should be in base_roles_map"
  }

  assert {
    condition     = !contains(keys(local.dependent_roles_map), "standalone_user")
    error_message = "Role without 'roles' attribute should NOT be in dependent_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Role with only built-in PostgreSQL roles should be classified as base
# -----------------------------------------------------------------------------

run "role_with_only_builtin_roles_is_base" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name  = "monitoring_user"
        roles = ["pg_monitor", "pg_read_all_stats"]
      }
    }]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "monitoring_user")
    error_message = "Role with only built-in roles should be in base_roles_map"
  }

  assert {
    condition     = !contains(keys(local.dependent_roles_map), "monitoring_user")
    error_message = "Role with only built-in roles should NOT be in dependent_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Role referencing a custom role should be classified as dependent
# -----------------------------------------------------------------------------

run "role_referencing_custom_role_is_dependent" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "base_role"
        }
      },
      {
        role = {
          name  = "child_role"
          roles = ["base_role"]
        }
      }
    ]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "base_role")
    error_message = "Parent role should be in base_roles_map"
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "child_role")
    error_message = "Role referencing custom role should be in dependent_roles_map"
  }

  assert {
    condition     = !contains(keys(local.base_roles_map), "child_role")
    error_message = "Role referencing custom role should NOT be in base_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Role with both built-in AND custom roles should be classified as dependent
# -----------------------------------------------------------------------------

run "role_with_builtin_and_custom_roles_is_dependent" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "app_role"
        }
      },
      {
        role = {
          name  = "admin_role"
          roles = ["pg_monitor", "app_role"]
        }
      }
    ]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "app_role")
    error_message = "Role without dependencies should be in base_roles_map"
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "admin_role")
    error_message = "Role with mixed built-in and custom roles should be in dependent_roles_map"
  }

  assert {
    condition     = !contains(keys(local.base_roles_map), "admin_role")
    error_message = "Role with mixed built-in and custom roles should NOT be in base_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Verify builtin_roles list contains expected PostgreSQL roles
# -----------------------------------------------------------------------------

run "builtin_roles_list_is_populated" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles     = []
  }

  assert {
    condition     = contains(local.builtin_roles, "pg_monitor")
    error_message = "builtin_roles should contain pg_monitor"
  }

  assert {
    condition     = contains(local.builtin_roles, "pg_read_all_data")
    error_message = "builtin_roles should contain pg_read_all_data"
  }

  assert {
    condition     = contains(local.builtin_roles, "pg_write_all_data")
    error_message = "builtin_roles should contain pg_write_all_data"
  }
}

# -----------------------------------------------------------------------------
# Test: custom_role_names contains all defined role names
# -----------------------------------------------------------------------------

run "custom_role_names_contains_all_roles" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "role_a"
        }
      },
      {
        role = {
          name = "role_b"
        }
      },
      {
        role = {
          name  = "role_c"
          roles = ["role_a"]
        }
      }
    ]
  }

  assert {
    condition     = length(local.custom_role_names) == 3
    error_message = "custom_role_names should contain all 3 roles"
  }

  assert {
    condition     = contains(local.custom_role_names, "role_a")
    error_message = "custom_role_names should contain role_a"
  }

  assert {
    condition     = contains(local.custom_role_names, "role_b")
    error_message = "custom_role_names should contain role_b"
  }

  assert {
    condition     = contains(local.custom_role_names, "role_c")
    error_message = "custom_role_names should contain role_c"
  }
}

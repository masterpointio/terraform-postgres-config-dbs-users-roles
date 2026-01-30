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

# -----------------------------------------------------------------------------
# Test: Multiple roles with complex inheritance chains
# -----------------------------------------------------------------------------

run "three_tier_role_inheritance" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "tier1_base"
        }
      },
      {
        role = {
          name  = "tier2_mid"
          roles = ["tier1_base"]
        }
      },
      {
        role = {
          name  = "tier3_top"
          roles = ["tier2_mid"]
        }
      }
    ]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "tier1_base")
    error_message = "tier1_base should be in base_roles_map"
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "tier2_mid")
    error_message = "tier2_mid should be in dependent_roles_map"
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "tier3_top")
    error_message = "tier3_top should be in dependent_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Verify passwords are properly merged
# -----------------------------------------------------------------------------

run "roles_with_passwords_merges_correctly" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name     = "explicit_password_role"
          password = "my_secure_password"
        }
      },
      {
        role = {
          name = "generated_password_role"
        }
      }
    ]
  }

  assert {
    condition     = local._roles_with_passwords[0].role.password == "my_secure_password"
    error_message = "Explicit password should be preserved"
  }

  assert {
    condition     = length(local._roles_with_passwords) == 2
    error_message = "Both roles should be in _roles_with_passwords"
  }
}

# -----------------------------------------------------------------------------
# Test: Empty roles list doesn't cause errors
# -----------------------------------------------------------------------------

run "empty_roles_creates_empty_maps" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles     = []
  }

  assert {
    condition     = length(local.base_roles_map) == 0
    error_message = "base_roles_map should be empty"
  }

  assert {
    condition     = length(local.dependent_roles_map) == 0
    error_message = "dependent_roles_map should be empty"
  }

  assert {
    condition     = length(local.custom_role_names) == 0
    error_message = "custom_role_names should be empty"
  }
}

# -----------------------------------------------------------------------------
# Test: Role with empty roles list should be base role
# -----------------------------------------------------------------------------

run "role_with_empty_roles_list_is_base" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name  = "empty_list_role"
        roles = []
      }
    }]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "empty_list_role")
    error_message = "Role with empty roles list should be in base_roles_map"
  }

  assert {
    condition     = !contains(keys(local.dependent_roles_map), "empty_list_role")
    error_message = "Role with empty roles list should NOT be in dependent_roles_map"
  }
}

# -----------------------------------------------------------------------------
# Test: Role referencing both builtin and custom roles
# -----------------------------------------------------------------------------

run "role_mixing_builtin_and_custom_roles" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "custom_base"
        }
      },
      {
        role = {
          name  = "mixed_inheritance"
          roles = ["custom_base", "pg_read_all_data", "pg_monitor"]
        }
      }
    ]
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "mixed_inheritance")
    error_message = "Role with mixed inheritance should be dependent"
  }

  assert {
    condition     = length(local.dependent_roles_map["mixed_inheritance"].role.roles) == 3
    error_message = "Should preserve all inherited roles"
  }
}

# -----------------------------------------------------------------------------
# Test: Databases map structure
# -----------------------------------------------------------------------------

run "databases_map_structure" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = [
      {
        name             = "db1"
        connection_limit = 50
      },
      {
        name             = "db2"
        connection_limit = 100
      }
    ]
    roles = []
  }

  assert {
    condition     = length(local.databases_map) == 2
    error_message = "Should have 2 databases in map"
  }

  assert {
    condition     = local.databases_map["db1"].connection_limit == 50
    error_message = "db1 should have connection_limit of 50"
  }

  assert {
    condition     = local.databases_map["db2"].connection_limit == 100
    error_message = "db2 should have connection_limit of 100"
  }
}

# -----------------------------------------------------------------------------
# Test: Verify alltrue logic for built-in roles
# -----------------------------------------------------------------------------

run "alltrue_logic_for_builtin_roles" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [{
      role = {
        name  = "only_builtins"
        roles = ["pg_monitor", "pg_read_all_stats", "pg_read_all_settings"]
      }
    }]
  }

  assert {
    condition     = contains(keys(local.base_roles_map), "only_builtins")
    error_message = "Role with only built-in roles should be base"
  }

  assert {
    condition     = !contains(keys(local.dependent_roles_map), "only_builtins")
    error_message = "Role with only built-in roles should not be dependent"
  }
}

# -----------------------------------------------------------------------------
# Test: Verify anytrue logic for custom roles
# -----------------------------------------------------------------------------

run "anytrue_logic_for_custom_roles" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      {
        role = {
          name = "custom_role"
        }
      },
      {
        role = {
          name  = "has_one_custom"
          roles = ["pg_monitor", "custom_role"]
        }
      }
    ]
  }

  assert {
    condition     = contains(keys(local.dependent_roles_map), "has_one_custom")
    error_message = "Role with any custom role should be dependent"
  }
}

# -----------------------------------------------------------------------------
# Test: Password generation count matches roles count
# -----------------------------------------------------------------------------

run "password_generation_count" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  variables {
    databases = []
    roles = [
      { role = { name = "role1" } },
      { role = { name = "role2" } },
      { role = { name = "role3" } }
    ]
  }

  assert {
    condition     = length(local._roles_with_passwords) == 3
    error_message = "Should generate passwords for all roles"
  }
}
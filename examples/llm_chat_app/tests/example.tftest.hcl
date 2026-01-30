mock_provider "postgresql" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test: Module properly references parent module
# -----------------------------------------------------------------------------

run "module_references_parent" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = module.postgres_automation != null
    error_message = "Module should reference parent postgres_automation module"
  }
}

# -----------------------------------------------------------------------------
# Test: Schemas are created with correct owners
# -----------------------------------------------------------------------------

run "schemas_created_with_migration_owner" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_schema.app.name == "app"
    error_message = "app schema should be created"
  }

  assert {
    condition     = postgresql_schema.app.owner == "role_service_migration"
    error_message = "app schema should be owned by role_service_migration"
  }

  assert {
    condition     = postgresql_schema.ref_data_pipeline_abc.name == "ref_data_pipeline_abc"
    error_message = "ref_data_pipeline_abc schema should be created"
  }

  assert {
    condition     = postgresql_schema.ref_data_pipeline_xyz.name == "ref_data_pipeline_xyz"
    error_message = "ref_data_pipeline_xyz schema should be created"
  }
}

# -----------------------------------------------------------------------------
# Test: RW role app schema grants exist
# -----------------------------------------------------------------------------

run "rw_role_app_schema_grants" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.rw_app_schema.role == "role_service_rw"
    error_message = "RW role should have app schema grants"
  }

  assert {
    condition     = postgresql_grant.rw_app_schema.schema == "app"
    error_message = "RW grant should be for app schema"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_schema.privileges, "USAGE")
    error_message = "RW role should have USAGE privilege on app schema"
  }

  assert {
    condition     = postgresql_grant.rw_app_tables.object_type == "table"
    error_message = "RW role should have table grants"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_tables.privileges, "SELECT")
    error_message = "RW role should have SELECT on tables"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_tables.privileges, "INSERT")
    error_message = "RW role should have INSERT on tables"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_tables.privileges, "UPDATE")
    error_message = "RW role should have UPDATE on tables"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_tables.privileges, "DELETE")
    error_message = "RW role should have DELETE on tables"
  }
}

# -----------------------------------------------------------------------------
# Test: RW role does NOT have TRUNCATE privilege
# -----------------------------------------------------------------------------

run "rw_role_no_truncate" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = !contains(postgresql_grant.rw_app_tables.privileges, "TRUNCATE")
    error_message = "RW role should NOT have TRUNCATE privilege"
  }
}

# -----------------------------------------------------------------------------
# Test: RO role app schema grants exist
# -----------------------------------------------------------------------------

run "ro_role_app_schema_grants" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.ro_app_schema.role == "role_service_ro"
    error_message = "RO role should have app schema grants"
  }

  assert {
    condition     = contains(postgresql_grant.ro_app_tables.privileges, "SELECT")
    error_message = "RO role should have SELECT on tables"
  }

  assert {
    condition     = length(postgresql_grant.ro_app_tables.privileges) == 1
    error_message = "RO role should ONLY have SELECT privilege"
  }
}

# -----------------------------------------------------------------------------
# Test: PUBLIC privileges are revoked
# -----------------------------------------------------------------------------

run "public_privileges_revoked" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.revoke_public_connect.role == "public"
    error_message = "Should revoke PUBLIC database privileges"
  }

  assert {
    condition     = length(postgresql_grant.revoke_public_connect.privileges) == 0
    error_message = "PUBLIC should have empty privileges on database"
  }

  assert {
    condition     = postgresql_grant.revoke_public_schema.role == "public"
    error_message = "Should revoke PUBLIC schema privileges"
  }

  assert {
    condition     = length(postgresql_grant.revoke_public_schema.privileges) == 0
    error_message = "PUBLIC should have empty privileges on schema"
  }
}

# -----------------------------------------------------------------------------
# Test: Migration role has DDL privileges
# -----------------------------------------------------------------------------

run "migration_role_ddl_privileges" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.migration_app_schema.role == "role_service_migration"
    error_message = "Migration role should have app schema grants"
  }

  assert {
    condition     = contains(postgresql_grant.migration_app_schema.privileges, "CREATE")
    error_message = "Migration role should have CREATE privilege"
  }

  assert {
    condition     = contains(postgresql_grant.migration_app_tables.privileges, "TRUNCATE")
    error_message = "Migration role should have TRUNCATE privilege"
  }
}

# -----------------------------------------------------------------------------
# Test: Pipeline roles have access to ref_data schemas
# -----------------------------------------------------------------------------

run "pipeline_roles_ref_data_access" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.pipeline_rw_abc_schema.role == "service_pipeline_rw"
    error_message = "Pipeline RW should have abc schema access"
  }

  assert {
    condition     = postgresql_grant.pipeline_rw_xyz_schema.role == "service_pipeline_rw"
    error_message = "Pipeline RW should have xyz schema access"
  }

  assert {
    condition     = postgresql_grant.pipeline_ro_abc_schema.role == "service_pipeline_ro"
    error_message = "Pipeline RO should have abc schema access"
  }

  assert {
    condition     = postgresql_grant.pipeline_ro_xyz_schema.role == "service_pipeline_ro"
    error_message = "Pipeline RO should have xyz schema access"
  }
}

# -----------------------------------------------------------------------------
# Test: Default privileges for ref_data schemas
# -----------------------------------------------------------------------------

run "ref_data_default_privileges" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_default_privileges.pipeline_rw_abc_tables.owner == "role_service_migration"
    error_message = "Default privileges should be for objects owned by migration role"
  }

  assert {
    condition     = postgresql_default_privileges.pipeline_rw_abc_tables.role == "service_pipeline_rw"
    error_message = "Default privileges should grant to pipeline_rw role"
  }

  assert {
    condition     = contains(postgresql_default_privileges.pipeline_rw_abc_tables.privileges, "SELECT")
    error_message = "Default privileges should include SELECT"
  }

  assert {
    condition     = postgresql_default_privileges.pipeline_ro_abc_tables.role == "service_pipeline_ro"
    error_message = "RO default privileges should grant to pipeline_ro role"
  }

  assert {
    condition     = length(postgresql_default_privileges.pipeline_ro_abc_tables.privileges) == 1
    error_message = "RO default privileges should only have SELECT"
  }
}

# -----------------------------------------------------------------------------
# Test: All schemas have default privileges for functions
# -----------------------------------------------------------------------------

run "function_execute_privileges" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_default_privileges.rw_app_functions.object_type == "function"
    error_message = "Should have function default privileges for RW role"
  }

  assert {
    condition     = contains(postgresql_default_privileges.rw_app_functions.privileges, "EXECUTE")
    error_message = "Should grant EXECUTE on functions"
  }

  assert {
    condition     = postgresql_default_privileges.ro_app_functions.object_type == "function"
    error_message = "Should have function default privileges for RO role"
  }

  assert {
    condition     = contains(postgresql_default_privileges.ro_app_functions.privileges, "EXECUTE")
    error_message = "RO role should also have EXECUTE on functions"
  }
}

# -----------------------------------------------------------------------------
# Test: Sequence privileges are granted
# -----------------------------------------------------------------------------

run "sequence_privileges" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_grant.rw_app_sequences.object_type == "sequence"
    error_message = "Should grant sequence privileges to RW role"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_sequences.privileges, "USAGE")
    error_message = "Should grant USAGE on sequences"
  }

  assert {
    condition     = contains(postgresql_grant.rw_app_sequences.privileges, "UPDATE")
    error_message = "RW role should have UPDATE on sequences"
  }

  assert {
    condition     = postgresql_grant.ro_app_sequences.object_type == "sequence"
    error_message = "Should grant sequence privileges to RO role"
  }

  assert {
    condition     = !contains(postgresql_grant.ro_app_sequences.privileges, "UPDATE")
    error_message = "RO role should NOT have UPDATE on sequences"
  }
}

# -----------------------------------------------------------------------------
# Test: Dependencies are properly set
# -----------------------------------------------------------------------------

run "resource_dependencies" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  # Verify schemas depend on module
  assert {
    condition     = length([for dep in postgresql_schema.app.depends_on : dep if can(regex("module.postgres_automation", dep))]) > 0
    error_message = "Schema should depend on postgres_automation module"
  }

  # Verify grants depend on both module and schemas
  assert {
    condition     = length([for dep in postgresql_grant.rw_app_schema.depends_on : dep if can(regex("postgresql_schema.app", dep))]) > 0
    error_message = "Grants should depend on schema creation"
  }
}

# -----------------------------------------------------------------------------
# Test: Database is correctly referenced
# -----------------------------------------------------------------------------

run "database_references" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  assert {
    condition     = postgresql_schema.app.database == "llm_service"
    error_message = "Schemas should reference llm_service database"
  }

  assert {
    condition     = postgresql_grant.rw_app_schema.database == "llm_service"
    error_message = "Grants should reference llm_service database"
  }
}

# -----------------------------------------------------------------------------
# Test: All three schemas have consistent grant patterns
# -----------------------------------------------------------------------------

run "consistent_grant_patterns_across_schemas" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  # Migration role should have grants on all 3 schemas
  assert {
    condition     = postgresql_grant.migration_app_schema.schema == "app"
    error_message = "Migration should have app schema grants"
  }

  assert {
    condition     = postgresql_grant.migration_abc_schema.schema == "ref_data_pipeline_abc"
    error_message = "Migration should have abc schema grants"
  }

  assert {
    condition     = postgresql_grant.migration_xyz_schema.schema == "ref_data_pipeline_xyz"
    error_message = "Migration should have xyz schema grants"
  }

  # All migration grants should have both USAGE and CREATE
  assert {
    condition     = contains(postgresql_grant.migration_app_schema.privileges, "USAGE")
    error_message = "Migration should have USAGE on app"
  }

  assert {
    condition     = contains(postgresql_grant.migration_abc_schema.privileges, "CREATE")
    error_message = "Migration should have CREATE on abc"
  }

  assert {
    condition     = contains(postgresql_grant.migration_xyz_schema.privileges, "CREATE")
    error_message = "Migration should have CREATE on xyz"
  }
}

# -----------------------------------------------------------------------------
# Test: Pipeline RW has TRUNCATE but FastAPI RW does not
# -----------------------------------------------------------------------------

run "truncate_privilege_differences" {
  command = plan

  providers = {
    postgresql = postgresql.mock
  }

  # Pipeline RW should have TRUNCATE on ref_data schemas
  assert {
    condition     = contains(postgresql_grant.pipeline_rw_abc_tables.privileges, "TRUNCATE")
    error_message = "Pipeline RW should have TRUNCATE on abc tables"
  }

  assert {
    condition     = contains(postgresql_grant.pipeline_rw_xyz_tables.privileges, "TRUNCATE")
    error_message = "Pipeline RW should have TRUNCATE on xyz tables"
  }

  # FastAPI RW should NOT have TRUNCATE on app schema
  assert {
    condition     = !contains(postgresql_grant.rw_app_tables.privileges, "TRUNCATE")
    error_message = "FastAPI RW should NOT have TRUNCATE on app tables"
  }
}
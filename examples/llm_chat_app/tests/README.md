# LLM Chat App Example - Tests

This directory contains comprehensive tests for the llm_chat_app example.

## Test Files

### `example.tftest.hcl`
Terraform native tests for the example configuration:
- Module integration with parent module
- Schema creation and ownership
- Role-based access control (RBAC) grants
- PUBLIC privilege revocation
- Migration role DDL privileges
- Pipeline role access patterns
- Default privileges configuration

**Test Count**: 15+ test scenarios

### `scripts_test.sh`
Shell script integration tests that validate:
- Script existence and executability
- Bash syntax validation
- Error handling (`set -e`)
- Environment variable setup
- Test object creation
- Verification test logic
- Cleanup procedures
- Proper ordering of operations

**Test Count**: 20 comprehensive checks

## Running Tests

### Run Terraform Tests
```bash
cd examples/llm_chat_app
terraform test
```

### Run Shell Script Tests
```bash
cd examples/llm_chat_app
./tests/scripts_test.sh
```

## Test Coverage by Component

### Schema Tests
- ✅ `app` schema created with correct owner
- ✅ `ref_data_pipeline_abc` schema created
- ✅ `ref_data_pipeline_xyz` schema created
- ✅ All schemas owned by `role_service_migration`

### Grant Tests

#### RW (Read-Write) Role
- ✅ USAGE on app schema
- ✅ SELECT, INSERT, UPDATE, DELETE on tables
- ✅ No TRUNCATE privilege (security boundary)
- ✅ USAGE, SELECT, UPDATE on sequences
- ✅ EXECUTE on functions

#### RO (Read-Only) Role
- ✅ USAGE on app schema
- ✅ SELECT only on tables
- ✅ USAGE, SELECT on sequences
- ✅ EXECUTE on functions

#### Migration Role
- ✅ CREATE on all schemas
- ✅ TRUNCATE on tables (DDL operations)
- ✅ Full privileges on all object types

#### Pipeline Roles
- ✅ Access to all schemas (app, ref_data_pipeline_abc, ref_data_pipeline_xyz)
- ✅ RW role has TRUNCATE on ref_data schemas
- ✅ RO role has SELECT only on all schemas

### Security Tests
- ✅ PUBLIC database privileges revoked
- ✅ PUBLIC schema privileges revoked
- ✅ RW roles do NOT have TRUNCATE on app schema
- ✅ RO roles limited to SELECT

### Default Privileges Tests
- ✅ Future objects automatically granted to roles
- ✅ Correct owner (role_service_migration) specified
- ✅ Function EXECUTE privileges
- ✅ Separate grants for RW and RO roles

### Shell Script Tests

#### Script Validation
- ✅ All scripts exist
- ✅ Scripts are executable
- ✅ Bash shebang present
- ✅ Error handling (`set -e`)
- ✅ Valid bash syntax

#### Script Functionality
- ✅ 1_apply_terraform.sh calls `tofu apply`
- ✅ 2_create_test_objects.sh sets environment variables
- ✅ 2_create_test_objects.sh creates test objects
- ✅ 3_run_verification_tests.sh runs 8+ tests
- ✅ 3_run_verification_tests.sh tests TRUNCATE denial
- ✅ 4_cleanup.sh terminates connections
- ✅ 4_cleanup.sh drops resources in correct order
- ✅ RUN_ALL_TESTS.sh orchestrates all scripts

#### Best Practices
- ✅ Proper password variable usage
- ✅ SET ROLE for ownership
- ✅ PGUSER and PGPASSWORD patterns
- ✅ Quoted heredocs for SQL
- ✅ Preserves admin_user
- ✅ Descriptive output

## Test Scenarios

### Scenario 1: Module Integration
Tests that the example properly references and configures the parent module.

### Scenario 2: Schema Ownership Model
Validates the ownership model where `role_service_migration` owns all schemas and objects.

### Scenario 3: Permission Boundaries
Ensures proper permission boundaries:
- FastAPI roles limited to app schema
- Pipeline roles have cross-schema access
- RW roles lack DDL privileges (no TRUNCATE on app)
- RO roles limited to SELECT

### Scenario 4: Security Hardening
Tests security measures:
- PUBLIC privileges revoked
- Explicit grant model (no implicit permissions)
- Migration role has full DDL access
- Application roles have limited DML access

### Scenario 5: Default Privileges
Validates that future objects automatically grant correct permissions without manual intervention.

## Key Assertions

### No TRUNCATE for Application Roles on App Schema
```hcl
assert {
  condition     = !contains(postgresql_grant.rw_app_tables.privileges, "TRUNCATE")
  error_message = "RW role should NOT have TRUNCATE privilege"
}
```

This is critical for preventing accidental data loss in production.

### Pipeline Roles Have TRUNCATE on ref_data Schemas
```hcl
assert {
  condition     = contains(postgresql_grant.pipeline_rw_abc_tables.privileges, "TRUNCATE")
  error_message = "Pipeline RW should have TRUNCATE on abc tables"
}
```

This allows data pipelines to efficiently reload reference data.

### Function EXECUTE Privileges
```hcl
assert {
  condition     = contains(postgresql_default_privileges.rw_app_functions.privileges, "EXECUTE")
  error_message = "Should grant EXECUTE on functions"
}
```

Ensures both RW and RO roles can execute database functions.

## Shell Script Testing Philosophy

The shell script tests validate that:
1. Scripts follow bash best practices
2. SQL is properly quoted (heredocs)
3. Environment variables are set correctly
4. Operations occur in proper order (dependencies)
5. Error handling is present
6. Security is maintained (admin_user preserved)

## Integration with Manual Testing

After running these automated tests, you can perform manual testing:

```bash
# 1. Apply infrastructure
./1_apply_terraform.sh

# 2. Create test objects
./2_create_test_objects.sh

# 3. Run verification tests
./3_run_verification_tests.sh

# 4. Cleanup
./4_cleanup.sh
```

## CI/CD Considerations

### Terraform Tests
Can run without a real database (uses mock provider):
```bash
terraform test
```

### Shell Script Tests
Run quickly without infrastructure:
```bash
./tests/scripts_test.sh
```

### Integration Tests
Require a PostgreSQL instance and should run in a separate job:
```bash
# Requires PGHOST, PGPORT, and admin_user setup
./RUN_ALL_TESTS.sh
```

## Known Patterns

### Permission Escalation Prevention
The example demonstrates preventing privilege escalation:
- Login roles inherit from group roles
- Group roles have no login
- Prevents direct credential theft via group role impersonation

### Least Privilege Principle
Each role has minimum required privileges:
- FastAPI RO: Only SELECT
- FastAPI RW: No TRUNCATE (prevents accidental data loss)
- Pipeline roles: Full access to ref_data, limited to app schema

### Defense in Depth
Multiple security layers:
1. PUBLIC privileges revoked
2. Explicit grants only
3. Connection limits
4. Role inheritance model
5. Schema ownership model

## Troubleshooting

### Test Failures

If Terraform tests fail:
1. Check mock provider configuration
2. Verify variable types match schema
3. Review assertion logic
4. Check for typos in resource names

If shell script tests fail:
1. Ensure scripts have Unix line endings (LF not CRLF)
2. Verify bash is available
3. Check file permissions
4. Review bash syntax with `bash -n script.sh`

## Contributing

When modifying the example:
1. Update relevant tests
2. Add new tests for new features
3. Ensure all tests pass
4. Update test documentation
5. Consider adding shell script tests for new scripts

## Test Maintenance

These tests should be maintained when:
- Adding new roles
- Modifying permissions
- Adding new schemas
- Changing privilege patterns
- Adding new scripts
- Modifying cleanup procedures
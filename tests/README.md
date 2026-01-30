# Terraform Tests

This directory contains comprehensive tests for the terraform-postgres-config-dbs-users-roles module using Terraform's native testing framework.

## Test Files

### `locals.tftest.hcl`
Tests the local value computations and role classification logic:
- Role classification (base vs dependent roles)
- Built-in PostgreSQL role detection
- Custom role name extraction
- Role inheritance chains
- Password merging logic

**Key Tests:**
- Roles without `roles` attribute are classified as base roles
- Roles with only built-in PostgreSQL roles are base roles
- Roles referencing custom roles are dependent roles
- Complex multi-tier inheritance hierarchies
- Empty roles list handling

### `main.tftest.hcl`
Tests the main module resources and their interactions:
- Database creation
- Role creation (base and dependent)
- Password generation
- Grant resources (database, schema, table, sequence)
- Default privileges
- Edge cases and error conditions

**Key Tests:**
- Roles with and without passwords
- Random password generation (33 characters, no special chars)
- Multiple grant types per role
- Empty configurations
- Connection limits (including 0 and -1)
- Complex role hierarchies

### `outputs.tftest.hcl`
Tests all module outputs:
- `databases` output structure
- `roles` output (merged base + dependent)
- `base_roles` output
- `dependent_roles` output
- Grant outputs (database_access, schema_access, table_access, sequence_access)
- `default_privileges` output
- Sensitive flag on role outputs

**Key Tests:**
- Output structure and completeness
- Proper separation of base and dependent roles
- Empty configuration outputs
- Multiple resources in outputs

### `variables.tftest.hcl`
Tests variable validation and optional attributes:
- Default variable values
- Database variable with optional connection_limit
- Role variable with all optional attributes
- Grant configurations (database, schema, table, sequence)
- Default privileges
- Edge cases (empty lists, -1 connection limits)

**Key Tests:**
- Minimal vs fully-configured roles
- Optional attributes work correctly
- Multiple databases and roles
- Empty vs specific objects lists in grants
- Connection limit special values (0, -1)

## Running Tests

### Run All Tests
```bash
terraform test
```

### Run Specific Test File
```bash
terraform test -filter=tests/locals.tftest.hcl
```

### Run Specific Test
```bash
terraform test -filter=tests/locals.tftest.hcl -run=role_without_roles_attribute_is_base
```

## Test Structure

Each test file follows this structure:

1. **Mock Provider Setup**: Uses mock PostgreSQL provider to avoid requiring actual database
2. **Variables Block**: Sets input variables for shared test context
3. **Run Blocks**: Individual test cases with:
   - `command`: `plan` or `apply`
   - `providers`: Mock provider configuration
   - `variables`: Test-specific variable overrides (optional)
   - `assert`: One or more assertions

## Test Coverage

The test suite covers:

### Positive Tests
- ✅ Creating databases with and without connection limits
- ✅ Creating roles with various attributes
- ✅ Role classification (base vs dependent)
- ✅ Password generation and merging
- ✅ All grant types (database, schema, table, sequence)
- ✅ Default privileges
- ✅ Role inheritance chains
- ✅ Multiple databases and roles

### Negative/Edge Cases
- ✅ Empty databases and roles lists
- ✅ Null/optional attributes
- ✅ Empty objects lists (grant to all)
- ✅ Connection limit special values (0, -1)
- ✅ Complex role hierarchies
- ✅ Mixed built-in and custom role inheritance

### Regression Tests
- ✅ Password special characters exclusion (no `!#$%^&*()<>-_`)
- ✅ Password length (exactly 33 characters)
- ✅ Grant map key formats
- ✅ Built-in PostgreSQL roles list
- ✅ Role dependency ordering

## Assertion Patterns

### Existence Checks
```hcl
assert {
  condition     = contains(keys(local.base_roles_map), "role_name")
  error_message = "Role should be in base_roles_map"
}
```

### Value Checks
```hcl
assert {
  condition     = var.databases[0].connection_limit == 100
  error_message = "Connection limit should be preserved"
}
```

### Length Checks
```hcl
assert {
  condition     = length(local.custom_role_names) == 3
  error_message = "Should have 3 custom roles"
}
```

### Collection Checks
```hcl
assert {
  condition     = contains(postgresql_grant.rw_tables.privileges, "SELECT")
  error_message = "Should have SELECT privilege"
}
```

### Negation Checks
```hcl
assert {
  condition     = !contains(keys(local.dependent_roles_map), "base_role")
  error_message = "Base role should NOT be in dependent_roles_map"
}
```

## Test Naming Convention

Test names use snake_case and should be descriptive:
- `role_without_roles_attribute_is_base` - What is being tested and expected outcome
- `empty_databases_and_roles` - Edge case being tested
- `three_tier_role_inheritance` - Complex scenario being validated

## Mock Provider

Tests use a mock PostgreSQL provider to avoid requiring an actual database connection:

```hcl
mock_provider "postgresql" {
  alias = "mock"
}

run "test_name" {
  providers = {
    postgresql = postgresql.mock
  }
  # ... rest of test
}
```

This allows tests to:
- Run quickly without I/O
- Validate Terraform logic without infrastructure
- Run in CI/CD without database dependencies

## Best Practices

1. **One concept per test**: Each test should validate one specific behavior
2. **Clear error messages**: Assertions should have descriptive error messages
3. **Use variables block**: Share common test data across multiple runs
4. **Test both plan and apply**: Use `plan` for logic tests, `apply` for resource creation
5. **Test edge cases**: Empty lists, null values, special numbers (0, -1)
6. **Test failure modes**: Not just happy path

## Contributing

When adding new functionality:
1. Add tests for the new feature
2. Add tests for edge cases
3. Add tests for error conditions
4. Update this README if adding new test files
5. Ensure all tests pass: `terraform test`

## CI/CD Integration

These tests should be run in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Terraform Tests
  run: terraform test
```

No PostgreSQL database is required since tests use mock providers.
# LLM Chat App - Test Execution Instructions

This directory contains scripts to apply the Terraform configuration and run verification tests for the LLM Chat App example.

## Prerequisites

1. PostgreSQL instance running on `localhost:5432`
2. Admin user created:
   ```sql
   CREATE ROLE admin_user LOGIN CREATEROLE PASSWORD 'insecure-pass-for-demo-admin-user';
   ```
3. OpenTofu (tofu) installed
4. psql client installed

## Quick Start - Run Everything

To run all tasks in sequence:

```bash
cd examples/llm_chat_app
chmod +x RUN_ALL_TESTS.sh
./RUN_ALL_TESTS.sh
```

This will:

1. Apply the Terraform configuration (creates roles, database, schemas, grants)
2. Create test objects (tables, views, functions)
3. Run all verification tests

## Individual Steps

If you prefer to run steps individually:

### Step 1: Apply Terraform Configuration

```bash
chmod +x 1_apply_terraform.sh
./1_apply_terraform.sh
```

This runs `tofu apply -auto-approve` to create:

- Database: `llm_service`
- Roles: migration, group roles (rw/ro), login roles (fastapi_rw, fastapi_ro, pipeline_rw, pipeline_ro)
- Schemas: `app`, `ref_data_pipeline_abc`, `ref_data_pipeline_xyz`
- Grants and default privileges

### Step 2: Create Test Objects

```bash
chmod +x 2_create_test_objects.sh
./2_create_test_objects.sh
```

This creates:

- Test tables in `app` and `ref_data_*` schemas
- Test views
- Test function

### Step 3: Run Verification Tests

```bash
chmod +x 3_run_verification_tests.sh
./3_run_verification_tests.sh
```

This runs the following tests:

1. **Test 2: Migration Role DDL Access** - Verifies migration role can create/alter/drop objects
2. **Test 3: FastAPI RW Role** - Verifies DML on app schema and no DDL
3. **Test 4: FastAPI RO Role** - Verifies SELECT only
4. **Test 5: Pipeline RW Role** - Verifies access to all schemas
5. **Test 6: Pipeline RO Role** - Verifies read access to all schemas
6. **Test 7: Connection Limits** - Verifies connection limits are set correctly
7. **Test 8: Role Inheritance** - Verifies role memberships

## Expected Test Results

All tests should output:

- `TEST X PASSED: [description]`

If any test fails, you'll see an error message indicating the permission issue.

## Test Roles and Credentials

| Role                       | Password                    | Access Level              |
| -------------------------- | --------------------------- | ------------------------- |
| `role_service_migration`   | `demo-password-migration`   | DDL + DML on all schemas  |
| `role_service_fastapi_rw`  | `demo-password-fastapi-rw`  | DML on app schema only    |
| `role_service_fastapi_ro`  | `demo-password-fastapi-ro`  | SELECT on app schema only |
| `role_service_pipeline_rw` | `demo-password-pipeline-rw` | DML on all schemas        |
| `role_service_pipeline_ro` | `demo-password-pipeline-ro` | SELECT on all schemas     |

## Manual Test Commands

Example:

```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=llm_service

PGUSER=role_service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "SELECT * FROM app.test_users;"
```

## Cleanup

To destroy all resources:

```bash
cd examples/llm_chat_app
tofu destroy -auto-approve
```

## Troubleshooting

### Connection Refused

- Ensure PostgreSQL is running on localhost:5432
- Check pg_hba.conf allows password authentication

### Permission Denied

- Ensure `admin_user` role exists and has CREATEROLE privilege
- Check the password in `fixtures.auto.tfvars` matches your setup

### Role Already Exists

- If re-running, you may need to destroy first: `tofu destroy -auto-approve`
- Or manually drop roles: `DROP ROLE IF EXISTS role_service_* CASCADE;`

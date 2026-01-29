#!/bin/bash
# LLM Chat App - Apply Terraform and Run Verification Tests

set -e  # Exit on error

echo "=============================================="
echo "Task 1: Applying Terraform Configuration"
echo "=============================================="
echo ""

cd /Users/weston/clients/masterpoint/terraform-postgres-config-dbs-users-roles/examples/llm_chat_app

# Run terraform apply
tofu apply -auto-approve

echo ""
echo "=============================================="
echo "Terraform Apply Completed Successfully"
echo "=============================================="
echo ""
echo "=============================================="
echo "Task 2: Running Verification Tests"
echo "=============================================="
echo ""

# Set connection variables
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=llm_service

echo "--- Prerequisites: Creating Test Objects ---"
echo ""

PGUSER=role_service_migration PGPASSWORD=demo-password-migration psql <<'EOF'
-- Create test table in app schema
CREATE TABLE IF NOT EXISTS app.test_users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
INSERT INTO app.test_users (name) VALUES ('test') ON CONFLICT DO NOTHING;

-- Create test view in app schema
CREATE OR REPLACE VIEW app.test_users_view AS SELECT * FROM app.test_users;

-- Create test function in app schema
CREATE OR REPLACE FUNCTION app.test_func() RETURNS integer
LANGUAGE sql SECURITY INVOKER
AS $$ SELECT 1; $$;

-- Create test table in ref_data schemas
CREATE TABLE IF NOT EXISTS ref_data_pipeline_abc.test_ref (
    id SERIAL PRIMARY KEY,
    value TEXT
);
INSERT INTO ref_data_pipeline_abc.test_ref (value) VALUES ('abc') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS ref_data_pipeline_xyz.test_ref (
    id SERIAL PRIMARY KEY,
    value TEXT
);
INSERT INTO ref_data_pipeline_xyz.test_ref (value) VALUES ('xyz') ON CONFLICT DO NOTHING;

-- Create views in ref_data schemas
CREATE OR REPLACE VIEW ref_data_pipeline_abc.test_ref_view AS SELECT * FROM ref_data_pipeline_abc.test_ref;
CREATE OR REPLACE VIEW ref_data_pipeline_xyz.test_ref_view AS SELECT * FROM ref_data_pipeline_xyz.test_ref;
EOF

echo ""
echo "Test objects created successfully!"
echo ""
echo "=============================================="
echo "Running Verification Tests"
echo "=============================================="
echo ""

# Test 2: Migration Role DDL Access
echo "--- Test 2: Migration Role DDL Access ---"
PGUSER=role_service_migration PGPASSWORD=demo-password-migration PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
CREATE TABLE app.migration_test (id int);
ALTER TABLE app.migration_test ADD COLUMN name text;
DROP TABLE app.migration_test;
SELECT 'TEST 2 PASSED: Migration role has DDL access' AS result;
"
echo ""

# Test 3: FastAPI RW Role
echo "--- Test 3: FastAPI RW Role - DML on app schema ---"
PGUSER=role_service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT * FROM app.test_users;
INSERT INTO app.test_users (name) VALUES ('fastapi_test');
DELETE FROM app.test_users WHERE name = 'fastapi_test';
SELECT 'TEST 3 PASSED: FastAPI RW has app DML' AS result;
"
echo ""

# Test 4: FastAPI RO Role
echo "--- Test 4: FastAPI RO Role - SELECT only ---"
PGUSER=role_service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT * FROM app.test_users;
SELECT 'TEST 4 PASSED: FastAPI RO has SELECT' AS result;
"
echo ""

# Test 5: Pipeline RW Role
echo "--- Test 5: Pipeline RW Role - All schemas access ---"
PGUSER=role_service_pipeline_rw PGPASSWORD=demo-password-pipeline-rw PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 5 PASSED: Pipeline RW has all schemas access' AS result;
"
echo ""

# Test 6: Pipeline RO Role
echo "--- Test 6: Pipeline RO Role - Read access to all schemas ---"
PGUSER=role_service_pipeline_ro PGPASSWORD=demo-password-pipeline-ro PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 6 PASSED: Pipeline RO has SELECT on all schemas' AS result;
"
echo ""

# Test 7: Connection Limits
echo "--- Test 7: Connection Limits ---"
PGUSER=role_service_migration PGPASSWORD=demo-password-migration PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT rolname, rolconnlimit
FROM pg_roles
WHERE rolname LIKE 'role_service_%'
ORDER BY rolname;
"
echo ""

# Test 8: Role Inheritance
echo "--- Test 8: Role Inheritance ---"
PGUSER=role_service_migration PGPASSWORD=demo-password-migration PGHOST=localhost PGPORT=5432 PGDATABASE=llm_service psql -c "
SELECT
    r.rolname AS role,
    ARRAY_AGG(m.rolname) AS member_of
FROM pg_roles r
LEFT JOIN pg_auth_members am ON r.oid = am.member
LEFT JOIN pg_roles m ON am.roleid = m.oid
WHERE r.rolname LIKE 'role_service_%'
GROUP BY r.rolname
ORDER BY r.rolname;
"
echo ""

echo "=============================================="
echo "All Tests Completed!"
echo "=============================================="

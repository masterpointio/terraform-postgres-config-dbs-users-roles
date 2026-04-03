#!/bin/bash
# Run all verification tests

set -e

export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=llm_chat_app

echo "=============================================="
echo "Running Verification Tests"
echo "=============================================="
echo ""

# Test 1: Migration Role DDL Access
# Runs as the login role directly (no SET ROLE) to verify that inherit=true
# causes service_migrator to automatically inherit DDL privileges from role_service_migration.
echo "--- Test 1: Migration Role DDL Access (via inheritance, no SET ROLE) ---"
PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -c "
CREATE TABLE app.migration_test (id int);
ALTER TABLE app.migration_test ADD COLUMN name text;
INSERT INTO app.migration_test (id) VALUES (1);
TRUNCATE app.migration_test;
DROP TABLE app.migration_test;
SELECT 'TEST 1 PASSED: service_migrator inherits DDL access (including TRUNCATE) from role_service_migration' AS result;
"
echo ""

# Test 2: FastAPI RW Role - DML on app schema
echo "--- Test 2: FastAPI RW Role - DML on app schema ---"
PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "
SELECT * FROM app.test_users;
INSERT INTO app.test_users (name) VALUES ('fastapi_test');
UPDATE app.test_users SET name = 'fastapi_test_updated' WHERE name = 'fastapi_test';
DELETE FROM app.test_users WHERE name = 'fastapi_test_updated';
SELECT 'TEST 2 PASSED: FastAPI RW has app DML (SELECT/INSERT/UPDATE/DELETE)' AS result;
"
echo ""

# Test 2b: FastAPI RW Role - Verify TRUNCATE is denied
echo "--- Test 2b: FastAPI RW Role - Verify TRUNCATE denied ---"
if PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "TRUNCATE app.test_users;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 2b PASSED: FastAPI RW correctly denied TRUNCATE"
else
  echo "TEST 2b FAILED: FastAPI RW should not have TRUNCATE permission"
  exit 1
fi
echo ""

# Test 3: FastAPI RO Role - SELECT only
echo "--- Test 3: FastAPI RO Role - SELECT only ---"
PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "
SELECT * FROM app.test_users;
SELECT 'TEST 3 PASSED: FastAPI RO has SELECT' AS result;
"
echo ""

# Test 3b: FastAPI RO Role - Verify INSERT denied
echo "--- Test 3b: FastAPI RO Role - Verify INSERT denied ---"
if PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "INSERT INTO app.test_users (name) VALUES ('ro_should_fail');" 2>&1 | grep -q "permission denied"; then
  echo "TEST 3b PASSED: FastAPI RO correctly denied INSERT"
else
  echo "TEST 3b FAILED: FastAPI RO should not have INSERT permission"
  exit 1
fi
echo ""

# Test 3c: FastAPI RO Role - Verify UPDATE denied
echo "--- Test 3c: FastAPI RO Role - Verify UPDATE denied ---"
if PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "UPDATE app.test_users SET name = 'ro_should_fail' WHERE id = 1;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 3c PASSED: FastAPI RO correctly denied UPDATE"
else
  echo "TEST 3c FAILED: FastAPI RO should not have UPDATE permission"
  exit 1
fi
echo ""

# Test 3d: FastAPI RO Role - Verify DELETE denied
echo "--- Test 3d: FastAPI RO Role - Verify DELETE denied ---"
if PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "DELETE FROM app.test_users WHERE id = 1;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 3d PASSED: FastAPI RO correctly denied DELETE"
else
  echo "TEST 3d FAILED: FastAPI RO should not have DELETE permission"
  exit 1
fi
echo ""

# Test 4: Pipeline RW Role - Full DML + TRUNCATE on all schemas
echo "--- Test 4: Pipeline RW Role - Full DML + TRUNCATE on all schemas ---"
PGUSER=service_pipeline_rw PGPASSWORD=demo-password-pipeline-rw psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
INSERT INTO ref_data_pipeline_abc.test_ref (value) VALUES ('pipeline_test');
UPDATE ref_data_pipeline_abc.test_ref SET value = 'pipeline_test_updated' WHERE value = 'pipeline_test';
DELETE FROM ref_data_pipeline_abc.test_ref WHERE value = 'pipeline_test_updated';
INSERT INTO ref_data_pipeline_xyz.test_ref (value) VALUES ('pipeline_test');
TRUNCATE ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 4 PASSED: Pipeline RW has full DML + TRUNCATE on ref_data schemas' AS result;
"
echo ""

# Test 4b: Pipeline RW Role - Verify TRUNCATE denied on app schema
echo "--- Test 4b: Pipeline RW Role - Verify TRUNCATE denied on app schema ---"
if PGUSER=service_pipeline_rw PGPASSWORD=demo-password-pipeline-rw psql -c "TRUNCATE app.test_users;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 4b PASSED: Pipeline RW correctly denied TRUNCATE on app schema"
else
  echo "TEST 4b FAILED: Pipeline RW should not have TRUNCATE on app schema"
  exit 1
fi
echo ""

# Test 5: Pipeline RO Role - SELECT only on all schemas
echo "--- Test 5: Pipeline RO Role - SELECT only on all schemas ---"
PGUSER=service_pipeline_ro PGPASSWORD=demo-password-pipeline-ro psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 5 PASSED: Pipeline RO has SELECT on all schemas' AS result;
"
echo ""

# Test 5b: Pipeline RO Role - Verify INSERT denied on ref_data schema
echo "--- Test 5b: Pipeline RO Role - Verify INSERT denied on ref_data schema ---"
if PGUSER=service_pipeline_ro PGPASSWORD=demo-password-pipeline-ro psql -c "INSERT INTO ref_data_pipeline_abc.test_ref (value) VALUES ('ro_should_fail');" 2>&1 | grep -q "permission denied"; then
  echo "TEST 5b PASSED: Pipeline RO correctly denied INSERT on ref_data schema"
else
  echo "TEST 5b FAILED: Pipeline RO should not have INSERT on ref_data schema"
  exit 1
fi
echo ""

# Test 6: Cross-schema denial - fastapi roles cannot access ref_data schemas
echo "--- Test 6: Cross-schema denial - FastAPI roles cannot access ref_data schemas ---"
if PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "SELECT * FROM ref_data_pipeline_abc.test_ref;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 6 PASSED: FastAPI RW correctly denied access to ref_data schema"
else
  echo "TEST 6 FAILED: FastAPI RW should not have access to ref_data schema"
  exit 1
fi
echo ""

if PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "SELECT * FROM ref_data_pipeline_abc.test_ref;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 6b PASSED: FastAPI RO correctly denied access to ref_data schema"
else
  echo "TEST 6b FAILED: FastAPI RO should not have access to ref_data schema"
  exit 1
fi
echo ""

# Test 7: Connection Limits
echo "--- Test 7: Connection Limits ---"

check_connlimit() {
  local role="$1"
  local expected="$2"
  local actual

  actual=$(PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -tA -c "
SELECT rolconnlimit
FROM pg_roles
WHERE rolname = '${role}';
" | tr -d '[:space:]')

  if [ "$actual" = "$expected" ]; then
    echo "TEST 7 PASSED: ${role} has connection limit ${expected}"
  else
    echo "TEST 7 FAILED: ${role} should have connection limit ${expected}, got ${actual}"
    exit 1
  fi
}

check_connlimit "service_migrator" "5"
check_connlimit "service_fastapi_rw" "30"
check_connlimit "service_fastapi_ro" "30"
check_connlimit "service_pipeline_rw" "10"
check_connlimit "service_pipeline_ro" "10"
echo ""

# Test 8: Role Inheritance - all login and group roles
echo "--- Test 8: Role Inheritance ---"

check_membership() {
  local role="$1"
  local expected="$2"
  local actual

  actual=$(PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -tA -c "
SELECT COALESCE(m.rolname, '')
FROM pg_roles r
LEFT JOIN pg_auth_members am ON r.oid = am.member
LEFT JOIN pg_roles m ON am.roleid = m.oid
WHERE r.rolname = '${role}';
" | tr -d '[:space:]')

  if [ "$actual" = "$expected" ]; then
    echo "TEST 8 PASSED: ${role} inherits from ${expected}"
  else
    echo "TEST 8 FAILED: ${role} should inherit from ${expected}, got ${actual}"
    exit 1
  fi
}

check_membership "service_migrator" "role_service_migration"
check_membership "service_fastapi_rw" "role_service_rw"
check_membership "service_fastapi_ro" "role_service_ro"
check_membership "service_pipeline_rw" "role_service_rw"
check_membership "service_pipeline_ro" "role_service_ro"
echo ""

echo "=============================================="
echo "All Tests Completed!"
echo "=============================================="

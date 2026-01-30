#!/bin/bash
# Run all verification tests

set -e

export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=llm_service

echo "=============================================="
echo "Running Verification Tests"
echo "=============================================="
echo ""

# Test 2: Migration Role DDL Access
echo "--- Test 2: Migration Role DDL Access ---"
PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -c "
SET ROLE role_service_migration;
CREATE TABLE app.migration_test (id int);
ALTER TABLE app.migration_test ADD COLUMN name text;
INSERT INTO app.migration_test (id) VALUES (1);
TRUNCATE app.migration_test;
DROP TABLE app.migration_test;
SELECT 'TEST 2 PASSED: Migration role has DDL access (including TRUNCATE)' AS result;
"
echo ""

# Test 3: FastAPI RW Role
echo "--- Test 3: FastAPI RW Role - DML on app schema ---"
PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "
SELECT * FROM app.test_users;
INSERT INTO app.test_users (name) VALUES ('fastapi_test');
DELETE FROM app.test_users WHERE name = 'fastapi_test';
SELECT 'TEST 3 PASSED: FastAPI RW has app DML' AS result;
"
echo ""

# Test 3b: FastAPI RW Role - Verify TRUNCATE is denied
echo "--- Test 3b: FastAPI RW Role - Verify TRUNCATE denied ---"
if PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw psql -c "TRUNCATE app.test_users;" 2>&1 | grep -q "permission denied"; then
  echo "TEST 3b PASSED: FastAPI RW correctly denied TRUNCATE"
else
  echo "TEST 3b FAILED: FastAPI RW should not have TRUNCATE permission"
  exit 1
fi
echo ""

# Test 4: FastAPI RO Role
echo "--- Test 4: FastAPI RO Role - SELECT only ---"
PGUSER=service_fastapi_ro PGPASSWORD=demo-password-fastapi-ro psql -c "
SELECT * FROM app.test_users;
SELECT 'TEST 4 PASSED: FastAPI RO has SELECT' AS result;
"
echo ""

# Test 5: Pipeline RW Role
echo "--- Test 5: Pipeline RW Role - All schemas access ---"
PGUSER=service_pipeline_rw PGPASSWORD=demo-password-pipeline-rw psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 5 PASSED: Pipeline RW has all schemas access' AS result;
"
echo ""

# Test 6: Pipeline RO Role
echo "--- Test 6: Pipeline RO Role - Read access to all schemas ---"
PGUSER=service_pipeline_ro PGPASSWORD=demo-password-pipeline-ro psql -c "
SELECT * FROM app.test_users;
SELECT * FROM ref_data_pipeline_abc.test_ref;
SELECT * FROM ref_data_pipeline_xyz.test_ref;
SELECT 'TEST 6 PASSED: Pipeline RO has SELECT on all schemas' AS result;
"
echo ""

# Test 7: Connection Limits
echo "--- Test 7: Connection Limits ---"
PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -c "
SELECT rolname, rolconnlimit
FROM pg_roles
WHERE rolname LIKE 'role_service_%'
ORDER BY rolname;
"
echo ""

# Test 8: Role Inheritance
echo "--- Test 8: Role Inheritance ---"
PGUSER=service_migrator PGPASSWORD=demo-password-migrator psql -c "
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

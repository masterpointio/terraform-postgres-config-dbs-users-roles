#!/bin/bash
# Integration tests for shell scripts
# These tests verify the scripts have correct syntax and structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "Shell Script Tests"
echo "========================================"
echo ""

# Test 1: Verify all scripts exist
echo "Test 1: Verify all required scripts exist"
test -f "$EXAMPLE_DIR/1_apply_terraform.sh" || { echo "FAIL: 1_apply_terraform.sh not found"; exit 1; }
test -f "$EXAMPLE_DIR/2_create_test_objects.sh" || { echo "FAIL: 2_create_test_objects.sh not found"; exit 1; }
test -f "$EXAMPLE_DIR/3_run_verification_tests.sh" || { echo "FAIL: 3_run_verification_tests.sh not found"; exit 1; }
test -f "$EXAMPLE_DIR/4_cleanup.sh" || { echo "FAIL: 4_cleanup.sh not found"; exit 1; }
test -f "$EXAMPLE_DIR/RUN_ALL_TESTS.sh" || { echo "FAIL: RUN_ALL_TESTS.sh not found"; exit 1; }
test -f "$EXAMPLE_DIR/run_tests.sh" || { echo "FAIL: run_tests.sh not found"; exit 1; }
echo "PASS: All scripts exist"
echo ""

# Test 2: Verify scripts are executable or can be made executable
echo "Test 2: Verify scripts can be made executable"
chmod +x "$EXAMPLE_DIR/1_apply_terraform.sh"
chmod +x "$EXAMPLE_DIR/2_create_test_objects.sh"
chmod +x "$EXAMPLE_DIR/3_run_verification_tests.sh"
chmod +x "$EXAMPLE_DIR/4_cleanup.sh"
chmod +x "$EXAMPLE_DIR/RUN_ALL_TESTS.sh"
chmod +x "$EXAMPLE_DIR/run_tests.sh"
echo "PASS: All scripts are executable"
echo ""

# Test 3: Verify scripts have bash shebang
echo "Test 3: Verify scripts have bash shebang"
for script in 1_apply_terraform.sh 2_create_test_objects.sh 3_run_verification_tests.sh 4_cleanup.sh RUN_ALL_TESTS.sh run_tests.sh; do
    if ! head -n 1 "$EXAMPLE_DIR/$script" | grep -q "^#!/bin/bash"; then
        echo "FAIL: $script does not have bash shebang"
        exit 1
    fi
done
echo "PASS: All scripts have bash shebang"
echo ""

# Test 4: Verify scripts use 'set -e' for error handling
echo "Test 4: Verify scripts use 'set -e'"
for script in 1_apply_terraform.sh 2_create_test_objects.sh 3_run_verification_tests.sh 4_cleanup.sh RUN_ALL_TESTS.sh run_tests.sh; do
    if ! grep -q "^set -e" "$EXAMPLE_DIR/$script"; then
        echo "FAIL: $script does not use 'set -e'"
        exit 1
    fi
done
echo "PASS: All scripts use 'set -e'"
echo ""

# Test 5: Verify bash syntax is valid
echo "Test 5: Verify bash syntax is valid"
for script in 1_apply_terraform.sh 2_create_test_objects.sh 3_run_verification_tests.sh 4_cleanup.sh RUN_ALL_TESTS.sh run_tests.sh; do
    if ! bash -n "$EXAMPLE_DIR/$script"; then
        echo "FAIL: $script has syntax errors"
        exit 1
    fi
done
echo "PASS: All scripts have valid bash syntax"
echo ""

# Test 6: Verify 1_apply_terraform.sh calls tofu apply
echo "Test 6: Verify 1_apply_terraform.sh calls tofu apply"
if ! grep -q "tofu apply" "$EXAMPLE_DIR/1_apply_terraform.sh"; then
    echo "FAIL: 1_apply_terraform.sh does not call tofu apply"
    exit 1
fi
echo "PASS: 1_apply_terraform.sh calls tofu apply"
echo ""

# Test 7: Verify 2_create_test_objects.sh sets up PGHOST/PGPORT/PGDATABASE
echo "Test 7: Verify 2_create_test_objects.sh sets environment variables"
if ! grep -q "export PGHOST" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not set PGHOST"
    exit 1
fi
if ! grep -q "export PGPORT" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not set PGPORT"
    exit 1
fi
if ! grep -q "export PGDATABASE" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not set PGDATABASE"
    exit 1
fi
echo "PASS: 2_create_test_objects.sh sets environment variables"
echo ""

# Test 8: Verify 2_create_test_objects.sh creates test objects
echo "Test 8: Verify 2_create_test_objects.sh creates test tables"
if ! grep -q "CREATE TABLE.*app.test_users" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not create app.test_users"
    exit 1
fi
if ! grep -q "CREATE TABLE.*ref_data_pipeline_abc.test_ref" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not create ref_data test tables"
    exit 1
fi
echo "PASS: 2_create_test_objects.sh creates test tables"
echo ""

# Test 9: Verify 3_run_verification_tests.sh runs multiple tests
echo "Test 9: Verify 3_run_verification_tests.sh runs verification tests"
test_count=$(grep -c "^echo.*Test [0-9]" "$EXAMPLE_DIR/3_run_verification_tests.sh" || true)
if [ "$test_count" -lt 5 ]; then
    echo "FAIL: 3_run_verification_tests.sh should run at least 5 tests, found $test_count"
    exit 1
fi
echo "PASS: 3_run_verification_tests.sh runs $test_count tests"
echo ""

# Test 10: Verify 3_run_verification_tests.sh tests TRUNCATE denial
echo "Test 10: Verify 3_run_verification_tests.sh tests TRUNCATE denial"
if ! grep -q "TRUNCATE" "$EXAMPLE_DIR/3_run_verification_tests.sh"; then
    echo "FAIL: 3_run_verification_tests.sh does not test TRUNCATE"
    exit 1
fi
echo "PASS: 3_run_verification_tests.sh tests TRUNCATE denial"
echo ""

# Test 11: Verify 4_cleanup.sh terminates connections before dropping
echo "Test 11: Verify 4_cleanup.sh terminates connections"
if ! grep -q "pg_terminate_backend" "$EXAMPLE_DIR/4_cleanup.sh"; then
    echo "FAIL: 4_cleanup.sh does not terminate connections"
    exit 1
fi
echo "PASS: 4_cleanup.sh terminates connections"
echo ""

# Test 12: Verify 4_cleanup.sh drops resources in correct order
echo "Test 12: Verify 4_cleanup.sh drops resources in correct order"
# Should drop login roles before group roles
login_role_line=$(grep -n "DROP ROLE IF EXISTS.*service_migrator" "$EXAMPLE_DIR/4_cleanup.sh" | cut -d: -f1)
group_role_line=$(grep -n "DROP ROLE IF EXISTS.*role_service_migration" "$EXAMPLE_DIR/4_cleanup.sh" | cut -d: -f1)
if [ -z "$login_role_line" ] || [ -z "$group_role_line" ]; then
    echo "FAIL: 4_cleanup.sh does not drop both login and group roles"
    exit 1
fi
if [ "$login_role_line" -gt "$group_role_line" ]; then
    echo "FAIL: 4_cleanup.sh should drop login roles before group roles"
    exit 1
fi
echo "PASS: 4_cleanup.sh drops resources in correct order"
echo ""

# Test 13: Verify RUN_ALL_TESTS.sh calls all individual scripts
echo "Test 13: Verify RUN_ALL_TESTS.sh orchestrates all scripts"
if ! grep -q "1_apply_terraform.sh" "$EXAMPLE_DIR/RUN_ALL_TESTS.sh"; then
    echo "FAIL: RUN_ALL_TESTS.sh does not call 1_apply_terraform.sh"
    exit 1
fi
if ! grep -q "2_create_test_objects.sh" "$EXAMPLE_DIR/RUN_ALL_TESTS.sh"; then
    echo "FAIL: RUN_ALL_TESTS.sh does not call 2_create_test_objects.sh"
    exit 1
fi
if ! grep -q "3_run_verification_tests.sh" "$EXAMPLE_DIR/RUN_ALL_TESTS.sh"; then
    echo "FAIL: RUN_ALL_TESTS.sh does not call 3_run_verification_tests.sh"
    exit 1
fi
echo "PASS: RUN_ALL_TESTS.sh orchestrates all scripts"
echo ""

# Test 14: Verify RUN_ALL_TESTS.sh makes scripts executable
echo "Test 14: Verify RUN_ALL_TESTS.sh makes scripts executable"
if ! grep -q "chmod +x" "$EXAMPLE_DIR/RUN_ALL_TESTS.sh"; then
    echo "FAIL: RUN_ALL_TESTS.sh does not make scripts executable"
    exit 1
fi
echo "PASS: RUN_ALL_TESTS.sh makes scripts executable"
echo ""

# Test 15: Verify run_tests.sh uses correct password variables
echo "Test 15: Verify run_tests.sh uses correct password for migrator"
if ! grep -q "PGPASSWORD=demo-password-migrator" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh uses wrong password variable"
    exit 1
fi
echo "PASS: Scripts use correct password variables"
echo ""

# Test 16: Verify scripts use SET ROLE for migration operations
echo "Test 16: Verify scripts use SET ROLE for proper ownership"
if ! grep -q "SET ROLE role_service_migration" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not use SET ROLE"
    exit 1
fi
echo "PASS: Scripts use SET ROLE for proper ownership"
echo ""

# Test 17: Verify test scripts use proper connection variables
echo "Test 17: Verify test scripts use PGUSER and PGPASSWORD"
fastapi_test=$(grep -c "PGUSER=service_fastapi_rw PGPASSWORD=demo-password-fastapi-rw" "$EXAMPLE_DIR/3_run_verification_tests.sh" || true)
if [ "$fastapi_test" -lt 1 ]; then
    echo "FAIL: 3_run_verification_tests.sh does not test fastapi_rw role"
    exit 1
fi
echo "PASS: Test scripts use proper connection variables"
echo ""

# Test 18: Verify SQL heredocs are properly quoted
echo "Test 18: Verify SQL heredocs use proper quoting"
if ! grep -q "psql <<'EOF'" "$EXAMPLE_DIR/2_create_test_objects.sh"; then
    echo "FAIL: 2_create_test_objects.sh does not use quoted heredoc"
    exit 1
fi
echo "PASS: Scripts use properly quoted heredocs"
echo ""

# Test 19: Verify cleanup script preserves admin_user
echo "Test 19: Verify cleanup script preserves admin_user"
if grep -q "DROP.*admin_user" "$EXAMPLE_DIR/4_cleanup.sh"; then
    echo "FAIL: 4_cleanup.sh should not drop admin_user"
    exit 1
fi
if ! grep -q "admin_user was preserved" "$EXAMPLE_DIR/4_cleanup.sh"; then
    echo "FAIL: 4_cleanup.sh should mention preserving admin_user"
    exit 1
fi
echo "PASS: Cleanup script preserves admin_user"
echo ""

# Test 20: Verify scripts have descriptive output
echo "Test 20: Verify scripts have descriptive output"
for script in 1_apply_terraform.sh 2_create_test_objects.sh 3_run_verification_tests.sh 4_cleanup.sh; do
    if ! grep -q "^echo.*====" "$EXAMPLE_DIR/$script"; then
        echo "FAIL: $script does not have descriptive output headers"
        exit 1
    fi
done
echo "PASS: Scripts have descriptive output"
echo ""

echo "========================================"
echo "All Shell Script Tests Passed!"
echo "========================================"
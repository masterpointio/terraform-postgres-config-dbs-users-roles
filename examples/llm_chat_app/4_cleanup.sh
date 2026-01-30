#!/bin/bash
# Cleanup: Delete all resources created by the example (but not admin_user)

set -e

export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=postgres  # Connect to postgres db for cleanup

echo "=============================================="
echo "Cleaning Up Example Resources"
echo "=============================================="
echo ""

# Use admin_user to perform cleanup
export PGUSER=admin_user
export PGPASSWORD=insecure-pass-for-demo-admin-user

echo "Step 1: Terminating connections to llm_service database..."
psql -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'llm_service' AND pid <> pg_backend_pid();
" 2>/dev/null || true

echo ""
echo "Step 2: Dropping database llm_service..."
psql -c "DROP DATABASE IF EXISTS llm_service;"

echo ""
echo "Step 3: Dropping login roles..."
# Drop login roles first (they depend on group roles)
psql <<'EOF'
DROP ROLE IF EXISTS role_service_migrator;
DROP ROLE IF EXISTS role_service_fastapi_rw;
DROP ROLE IF EXISTS role_service_fastapi_ro;
DROP ROLE IF EXISTS role_service_pipeline_rw;
DROP ROLE IF EXISTS role_service_pipeline_ro;
EOF

echo ""
echo "Step 4: Dropping group roles..."
# Drop group roles (no dependencies)
psql <<'EOF'
DROP ROLE IF EXISTS role_service_migration;
DROP ROLE IF EXISTS role_service_rw;
DROP ROLE IF EXISTS role_service_ro;
EOF

echo ""
echo "Step 5: Dropping cluster-wide roles..."
psql <<'EOF'
DROP ROLE IF EXISTS role_pg_cluster_admin;
DROP ROLE IF EXISTS role_pg_monitoring;
EOF

echo ""
echo "Step 6: Verifying cleanup..."
psql -c "
SELECT rolname FROM pg_roles
WHERE rolname LIKE 'role_service_%' OR rolname LIKE 'role_pg_%'
ORDER BY rolname;
"

echo ""
echo "=============================================="
echo "Cleanup Completed Successfully!"
echo "=============================================="
echo ""
echo "Note: admin_user was preserved."
echo "To re-run the example, start with: ./1_apply_terraform.sh"

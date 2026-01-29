#!/bin/bash
# Create test objects for verification

set -e

export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=llm_service

echo "=============================================="
echo "Creating Test Objects"
echo "=============================================="
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

SELECT 'Test objects created successfully!' AS result;
EOF

echo ""
echo "=============================================="
echo "Test Objects Created Successfully!"
echo "=============================================="

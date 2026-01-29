#!/bin/bash
# Master script to run all tasks in sequence

set -e

SCRIPT_DIR="/Users/weston/clients/masterpoint/terraform-postgres-config-dbs-users-roles/examples/llm_chat_app"

echo "========================================"
echo "LLM Chat App - Complete Test Suite"
echo "========================================"
echo ""

# Make scripts executable
chmod +x "${SCRIPT_DIR}/1_apply_terraform.sh"
chmod +x "${SCRIPT_DIR}/2_create_test_objects.sh"
chmod +x "${SCRIPT_DIR}/3_run_verification_tests.sh"

# Step 1: Apply Terraform
echo "STEP 1/3: Applying Terraform Configuration..."
"${SCRIPT_DIR}/1_apply_terraform.sh"
echo ""

# Step 2: Create Test Objects
echo "STEP 2/3: Creating Test Objects..."
"${SCRIPT_DIR}/2_create_test_objects.sh"
echo ""

# Step 3: Run Verification Tests
echo "STEP 3/3: Running Verification Tests..."
"${SCRIPT_DIR}/3_run_verification_tests.sh"
echo ""

echo "========================================"
echo "ALL TASKS COMPLETED SUCCESSFULLY!"
echo "========================================"

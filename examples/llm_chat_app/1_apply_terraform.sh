#!/bin/bash
# Task 1: Apply Terraform Configuration

set -e

echo "=============================================="
echo "Applying Terraform Configuration"
echo "=============================================="
echo ""

cd /Users/weston/clients/masterpoint/terraform-postgres-config-dbs-users-roles/examples/llm_chat_app

tofu apply -auto-approve

echo ""
echo "=============================================="
echo "Terraform Apply Completed Successfully!"
echo "=============================================="

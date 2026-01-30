#!/bin/bash
# Task 1: Apply Terraform Configuration

set -e

echo "=============================================="
echo "Applying Terraform Configuration"
echo "=============================================="
echo ""

cd "$(dirname "${BASH_SOURCE[0]}")"

tofu apply -auto-approve

echo ""
echo "=============================================="
echo "Terraform Apply Completed Successfully!"
echo "=============================================="

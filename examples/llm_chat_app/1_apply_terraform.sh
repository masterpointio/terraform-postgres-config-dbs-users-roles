#!/bin/bash
# Task 1: Apply Terraform Configuration

set -e

echo "=============================================="
echo "Applying Terraform Configuration"
echo "=============================================="
echo ""

cd "$(dirname "${BASH_SOURCE[0]}")"

# -parallelism=1: the postgresql provider only locks per role, so concurrent
# grants race. Parallel applies fail intermittently on every Postgres version
# ("tuple concurrently updated" when two grants touch the same schema ACL) and
# reliably on PG16+ ("deadlock detected"), where the CREATEROLE admin is an
# implicit member of every role it creates and so shares every role lock.
tofu apply -auto-approve -parallelism=1

echo ""
echo "=============================================="
echo "Terraform Apply Completed Successfully!"
echo "=============================================="

# Example: Complete Setup for PostgreSQL Logical Databases

This example demonstrates how to set up PostgreSQL logical databases using Terraform. It includes configurations for both an application user and a read-only user.

## Prerequisites

- Terraform installed on your local machine.
- Access to a PostgreSQL instance where you can apply these configurations.

## Usage

1. Clone the repository and navigate to the `examples/complete` directory.
2. Review and update the `fixtures.tfvars` file with your specific configuration details.
3. Run the following Terraform commands to apply the configuration:

   ```bash
   terraform init
   terraform plan -var-file="fixtures.tfvars"
   terraform apply -var-file="fixtures.tfvars"
   ```

## Roles and Permissions

The `fixtures.tfvars` file defines two roles:

- **app1_app_user**: This role is intended for application use with the following permissions:

  - Can log in and is not a superuser.
  - Has all privileges on tables and sequences in the `app1_db` database.
  - Can use and create within the `public` schema.

- **app1_readonly_user**: This role is intended for read-only access with the following permissions:
  - Can log in and is not a superuser.
  - Has `SELECT` privileges on tables and `USAGE`, `SELECT` on sequences in the `app1_db` database.

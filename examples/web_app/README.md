# Example: Web (FastAPI) App setup

This example shows how to create roles for a FastAPI web application with thoughtful permission boundaries intended for a production setup.

## Prerequisites

- Terraform installed on your local machine.
- Access to a PostgreSQL instance where you can apply these configurations.

## Usage

1. Clone the repository and navigate to the `examples/web_app` directory.
2. Review and update the `fixtures.tfvars` file with your specific configuration details.
3. Run the following Terraform commands to apply the configuration:

```bash
terraform init

# cat out the databases and roles
cat fixtures.auto.vars

terraform plan
terraform apply
```

## Roles and Permissions

There are 3 roles in this example,

- **fastapi_app_owner**: owner of the `web_app` database.

  - This DB role is only used and accessed in the CI/CD
  - This role applies migrations (makes changes to the DB structure) prior to the application booting up

- **fastapi_app_writer**: writer role for the `web_app` database

  - This DB role is the primary role for the FastAPI application
  - This role has full Create, Read, Update, Delete abilities

- **fastapi_app_reader**: reader role for the `web_app` database.
  - This DB role is a secondary role for the FastAPI application
  - This role can only Read from the DB. For example, we'd use this role for `GET` http endpoints.
  - For production setups, we'd have this role connect to a Postgres Read-Replica Server to minimize the amount of DB traffic on Postgres Write-DB instance.

## NOTE about authentication on Mac with default settings

Some default `pg_hba.conf` Postgres settings will allow you to log into the
Postgres server without ensuring a valid password. We ran into this when
we installed `postgresql@17` via [Homebrew](https://brew.sh/)

Example `pg_hba.conf` settings that don't check for a valid password

```bash
$ PG_PASSWORD=doesNotMatter psql web_app -U fastapi_app_owner
psql (17.4 (Homebrew), server 17.2 (Homebrew))
Type "help" for help.
web_app=>
```

```bash
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```

If you want Postgres to check the password values, swap in these `pg_hba.conf` changes,

Example `pg_hba.conf` settings that require valid password values,

```bash
# Allow only "my_user" to connect without a password (local + IPv4 localhost)
local   all             my_user                                  trust
host    all             my_user          127.0.0.1/32            trust
# All other users must use a password (local + IPv4 localhost + IPv6 localhost + other hosts)
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
# Replication rules (if needed, otherwise you can remove them or secure similarly)
local   replication     all                                     md5
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5
```

```bash
$ PG_PASSWORD=insecure-pass-for-demo-fastapi-app-owner psql web_app -U fastapi_app_owner
psql (17.4 (Homebrew), server 17.2 (Homebrew))
Type "help" for help.
web_app=>
```

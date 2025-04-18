# complete/fixtures.tfvars

# postgres shell command to create this user:
# CREATE ROLE admin_user LOGIN CREATEDB PASSWORD 'insecure-pass-for-demo';
db_username = "admin_user"
db_password = "insecure-pass-for-demo"

db_scheme    = "postgres"
db_hostname  = "localhost"
db_port      = 5432
db_superuser = true
db_sslmode   = "disable"

databases = [
  {
    name             = "app1_db"
    connection_limit = 10
  },
  {
    name             = "app2_db"
    connection_limit = 20
  },
  {
    name             = "app3_db"
    connection_limit = 30
  }
]

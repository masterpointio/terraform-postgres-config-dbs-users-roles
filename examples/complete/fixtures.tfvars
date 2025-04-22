# complete/fixtures.tfvars

# postgres shell command to create this user:
# CREATE ROLE admin_user LOGIN CREATEDB PASSWORD 'insecure-pass-for-demo';
db_username = "admin_user"

db_password  = "insecure-pass-for-demo"
db_scheme    = "postgres"
db_hostname  = "localhost"
db_port      = 5432
db_superuser = false
db_sslmode   = "disable"

databases = [
  {
    name             = "app1_db"
    connection_limit = 10
  }
]

roles = [
  {
    role = {
      name      = "app1_app_user"
      login     = true
      superuser = false
      password  = "securepassword1"
    }

    table_grants = {
      role        = "app1_app_user"
      database    = "app1_db"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["ALL"]
    }

    schema_grants = {
      role        = "app1_app_user"
      database    = "app1_db"
      schema      = "public"
      object_type = "schema"
      privileges  = ["USAGE", "CREATE"]
    }

    sequence_grants = {
      role        = "app1_app_user"
      database    = "app1_db"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["ALL"]
    }

    default_privileges = [{
      role        = "app1_app_user"
      database    = "app1_db"
      schema      = "public"
      owner       = "app1_app_user"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["DELETE", "INSERT", "REFERENCES", "SELECT", "TRIGGER", "TRUNCATE", "UPDATE"]
    }]
  },
  {
    role = {
      name      = "app1_readonly_user"
      login     = true
      password  = "readonlypassword1"
      superuser = false
    }

    table_grants = {
      role        = "app1_readonly_user"
      database    = "app1_db"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["SELECT"]
    }

    sequence_grants = {
      role        = "app1_readonly_user"
      database    = "app1_db"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["USAGE", "SELECT"]
    }

    default_privileges = [
      {
        role        = "app1_readonly_user"
        database    = "app1_db"
        schema      = "public"
        owner       = "app1_app_user"
        object_type = "table"
        objects     = [] # empty list to grant all tables
        privileges  = ["SELECT"]
      },
      {
        role        = "app1_readonly_user"
        database    = "app1_db"
        schema      = "public"
        owner       = "app1_app_user"
        object_type = "sequence"
        objects     = [] # empty list to grant all sequences
        privileges  = ["USAGE", "SELECT"]
      },
    ]
  }
]

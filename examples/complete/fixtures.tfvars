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
    name             = "app"
    connection_limit = 10
  }
]

roles = [
  {
    role = {
      name      = "system_user"
      login     = true
      superuser = false
      password  = "insecure-pass-for-demo-app"
    }

    table_grants = {
      role        = "system_user"
      database    = "app"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["ALL"]
    }

    schema_grants = {
      role        = "system_user"
      database    = "app"
      schema      = "public"
      object_type = "schema"
      privileges  = ["USAGE", "CREATE"]
    }

    sequence_grants = {
      role        = "system_user"
      database    = "app"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["ALL"]
    }
  },
  {
    role = {
      name      = "readonly_user"
      login     = true
      password  = "insecure-pass-for-demo-readonly"
      superuser = false
    }

    table_grants = {
      role        = "readonly_user"
      database    = "app"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["SELECT"]
    }

    sequence_grants = {
      role        = "readonly_user"
      database    = "app"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["USAGE", "SELECT"]
    }

    default_privileges = [
      {
        role        = "readonly_user"
        database    = "app"
        schema      = "public"
        owner       = "system_user"
        object_type = "table"
        objects     = [] # empty list to grant all tables
        privileges  = ["SELECT"]
      },
      {
        role        = "readonly_user"
        database    = "app"
        schema      = "public"
        owner       = "system_user"
        object_type = "sequence"
        objects     = [] # empty list to grant all sequences
        privileges  = ["USAGE", "SELECT"]
      },
    ]
  }
]

# complete/fixtures.tfvars

# postgres shell command to create this user:
# CREATE ROLE admin_user LOGIN CREATEDB PASSWORD 'insecure-pass-for-demo-admin-user';
db_username = "admin_user"

db_password  = "insecure-pass-for-demo-admin-user"
db_scheme    = "postgres"
db_hostname  = "localhost"
db_port      = 5432
db_superuser = false
db_sslmode   = "disable"

databases = [
  {
    name             = "web_app"
    connection_limit = 10
  }
]

roles = [
  {
    role = {
      name      = "fastapi_app_admin"
      login     = true
      superuser = false
      password  = "insecure-pass-for-demo-fastapi-app-admin"
    }
    table_grants = {
      role        = "fastapi_app_admin"
      database    = "web_app"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["ALL"]
    }

    schema_grants = {
      role        = "fastapi_app_admin"
      database    = "web_app"
      schema      = "public"
      object_type = "schema"
      privileges  = ["USAGE", "CREATE"]
    }

    sequence_grants = {
      role        = "fastapi_app_admin"
      database    = "web_app"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["ALL"]
    }
  },
  {
    role = {
      name      = "fastapi_app_writer"
      login     = true
      superuser = false
      password  = "insecure-pass-for-demo-fastapi-app-writer"
    }

    table_grants = {
      role        = "fastapi_app_writer"
      database    = "web_app"
      schema      = "public"
      object_type = "table"
      objects     = []      # empty list to grant all tables
      privileges  = ["ALL"] # grant all privileges on tables to the writer role
    }

    schema_grants = {
      role        = "fastapi_app_writer"
      database    = "web_app"
      schema      = "public"
      object_type = "schema"
      privileges  = ["USAGE"] # write does not have create privileges
    }

    sequence_grants = {
      role        = "fastapi_app_writer"
      database    = "web_app"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["ALL"]
    }

    default_privileges = [
      {
        role        = "fastapi_app_writer"
        database    = "web_app"
        schema      = "public"
        owner       = "fastapi_app_admin"
        object_type = "table"
        objects     = [] # empty list to grant all tables
        privileges  = ["ALL"]
      },
      {
        role        = "fastapi_app_writer"
        database    = "web_app"
        schema      = "public"
        owner       = "fastapi_app_admin"
        object_type = "sequence"
        objects     = [] # empty list to grant all sequences
        privileges  = ["ALL"]
      },
    ]
  },
  {
    role = {
      name      = "fastapi_app_reader"
      login     = true
      password  = "insecure-pass-for-demo-fastapi-app-reader"
      superuser = false
    }

    table_grants = {
      role        = "fastapi_app_reader"
      database    = "web_app"
      schema      = "public"
      object_type = "table"
      objects     = [] # empty list to grant all tables
      privileges  = ["SELECT"]
    }

    sequence_grants = {
      role        = "fastapi_app_reader"
      database    = "web_app"
      schema      = "public"
      object_type = "sequence"
      objects     = [] # empty list to grant all sequences
      privileges  = ["USAGE", "SELECT"]
    }

    default_privileges = [
      {
        role        = "fastapi_app_reader"
        database    = "web_app"
        schema      = "public"
        owner       = "fastapi_app_admin"
        object_type = "table"
        objects     = [] # empty list to grant all tables
        privileges  = ["SELECT"]
      },
      {
        role        = "fastapi_app_reader"
        database    = "web_app"
        schema      = "public"
        owner       = "fastapi_app_admin"
        object_type = "sequence"
        objects     = [] # empty list to grant all sequences
        privileges  = ["USAGE", "SELECT"]
      },
    ]
  }
]

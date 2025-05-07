# complete/variables.tf

variable "db_hostname" {
  type        = string
  description = "The hostname of the database instance."
}

variable "db_username" {
  type        = string
  description = "The username of the database instance."
}

variable "db_password" {
  type        = string
  description = "The password of the database instance."
  sensitive   = true
}

variable "db_port" {
  type        = number
  description = "The port of the database instance."
}

variable "db_scheme" {
  type        = string
  description = "The scheme of the database instance."
}

variable "db_superuser" {
  type        = bool
  description = "Whether the database instance is a superuser."
}

variable "db_sslmode" {
  type        = string
  description = "The SSL mode of the database instance."
}

variable "databases" {
  type = list(object({
    name             = string
    connection_limit = number
  }))
  default = []
}


variable "roles" {
  type = list(object({
    role = object({
      # See defaults: https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_role
      name                      = string
      superuser                 = optional(bool)
      create_database           = optional(bool)
      create_role               = optional(bool)
      inherit                   = optional(bool)
      login                     = optional(bool)
      replication               = optional(bool)
      bypass_row_level_security = optional(bool)
      connection_limit          = optional(number)
      encrypted_password        = optional(bool)
      password                  = optional(string)
      roles                     = optional(list(string))
      search_path               = optional(list(string))
      valid_until               = optional(string)
      skip_drop_role            = optional(bool)
      skip_reassign_owned       = optional(bool)
      statement_timeout         = optional(number)
      assume_role               = optional(string)
    })
    default_privileges = optional(list(object({
      role        = string
      database    = string
      schema      = string
      owner       = string
      object_type = string
      privileges  = list(string)
    })))
    database_grants = optional(object({
      role        = string
      database    = string
      object_type = string
      privileges  = list(string)
    }))
    schema_grants = optional(object({
      role        = string
      database    = string
      schema      = string
      object_type = string
      privileges  = list(string)
    }))
    table_grants = optional(object({
      role        = string
      database    = string
      schema      = string
      object_type = string
      objects     = list(string)
      privileges  = list(string)
    }))
    sequence_grants = optional(object({
      role        = string
      database    = string
      schema      = string
      object_type = string
      objects     = list(string)
      privileges  = list(string)
    }))
  }))
  default     = []
  description = "List of static postgres roles to create and related permissions. These are for applications that use static credentials and don't use IAM DB Auth. See defaults: https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_role"
}

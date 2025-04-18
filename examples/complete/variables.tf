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
}

variable "db_port" {
  type        = number
  description = "The port of the database instance."
}

variable "databases" {
  type = list(object({
    name             = string
    connection_limit = number
  }))
}

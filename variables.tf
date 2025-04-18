variable "databases" {
  type = list(object({
    name             = string
    connection_limit = optional(number)
  }))
  description = "The logical database to create and configure"
}

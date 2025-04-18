# complete/versions.tf

terraform {
  required_version = "~> 1"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1"
    }
  }
}

terraform {
  required_version = "~> 1"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.3"
    }
  }
}

# complete/main.tf

module "postgres_automation" {
  source = "../../"

  databases = var.databases
  roles     = var.roles
}

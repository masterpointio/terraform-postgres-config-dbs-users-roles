# complete/main.tf

module "app_dbs" {
  source = "../../"

  databases = var.databases
  roles     = var.roles
}

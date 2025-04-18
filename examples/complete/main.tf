# complete.tf

module "app_dbs" {
  source = "../../"

  databases = var.databases
}

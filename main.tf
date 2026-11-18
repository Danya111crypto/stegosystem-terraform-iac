locals {
  env_prefix = terraform.workspace == "default" ? "blue" : terraform.workspace
  is_active  = local.env_prefix == var.active_slot
}

module "networking" {
  source             = "./modules/networking"
  vpc_cidr           = var.vpc_cidr
  environment        = local.env_prefix
  availability_zones = var.availability_zones
}

module "secrets" {
  source        = "./modules/secrets"
  environment   = local.env_prefix
  rotation_days = 30
}

module "compute" {
  source             = "./modules/compute"
  environment        = local.env_prefix
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  instance_type      = var.instance_type
  min_size           = local.is_active ? 2 : 1
  max_size           = 4
  desired_capacity   = local.is_active ? 2 : 1
}

module "database" {
  source                = "./modules/database"
  environment           = local.env_prefix
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  db_username           = module.secrets.db_username
  db_password           = module.secrets.db_password
}

module "monitoring" {
  source         = "./modules/monitoring"
  environment    = local.env_prefix
  primary_app_id = module.compute.app_instance_ids[0]
  lb_instance_id = module.compute.lb_instance_id
  db_instance_id = module.database.db_instance_id
}
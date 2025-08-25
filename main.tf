# Discover two available AZs and pass the first two to networking
data "aws_availability_zones" "this" {
  state = "available"
}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  vpc_cidr     = "10.1.0.0/16"

  # Use the first two AZs returned
  azs = [
    data.aws_availability_zones.this.names[0],
    data.aws_availability_zones.this.names[1]
  ]

  # /24s per requirement
  mgmt_cidrs = ["10.1.0.0/24", "10.1.1.0/24"]   # public (management)
  app_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"] # private (application)
  be_cidrs   = ["10.1.20.0/24", "10.1.21.0/24"] # private (backend)

  enable_nat_per_az = true
}

module "apploadbalancing" {
  source = "./modules/apploadbalancing"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.mgmt_public_subnet_ids
}

module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  mgmt_public_subnet_ids = module.networking.mgmt_public_subnet_ids
  app_subnet_ids         = module.networking.app_private_subnet_ids
  allowed_ssh_cidr       = var.allowed_ssh_cidr

  alb_sg_id          = module.apploadbalancing.alb_sg_id
  target_group_arn   = module.apploadbalancing.target_group_arn
  app_user_data_path = "${path.module}/userdata/apache_bootstrap.sh"
}

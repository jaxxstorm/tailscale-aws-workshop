locals {
  vpc_cidr            = "172.16.0.0/16"
  vpc_private_subnets = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
  vpc_public_subnets  = ["172.16.3.0/24", "172.16.4.0/24", "172.16.5.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name               = "tailscale-workshop-vpc"
  cidr               = local.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = true  # Use a single NAT gateway to save costs

  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = local.vpc_private_subnets
  public_subnets   = local.vpc_public_subnets
  database_subnets = local.vpc_private_subnets

  create_database_subnet_group = true

  tags = {
    Project = "tailscale-workshop"
  }
}

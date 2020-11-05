data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source                           = "terraform-aws-modules/vpc/aws"
  version                          = "2.64.0"
  name                             = "${var.namespace}-vpc"
  cidr                             = "172.16.0.0/16"
  azs                              = data.aws_availability_zones.available.names
  private_subnets                  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets                   = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  database_subnets                 = ["172.16.8.0/24", "172.16.9.0/24", "172.16.10.0/24"]
  assign_generated_ipv6_cidr_block = true
  create_database_subnet_group     = true
  enable_nat_gateway               = true
  single_nat_gateway               = true
}

module "lg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"
  # insert the 2 required variables here
  name   = "lg_sg"
  vcp_id = module.vpc.vcp_id
  ingress_rules = [{
    port        = 80
    cidr_blocks = ["0.0.0.0"]
  }]
}

module "websvr_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"
  # insert the 2 required variables here
  name   = "websvr_sg"
  vcp_id = module.vpc.vcp_id
  ingress_rules = [{
    port           = 8080
    security_group = [module.lg_sg.security_group.vcp_id]

    },
    {
      port        = 22
      cidr_blocks = ["172.16.0.0/16"]
  }]
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "2.1.0"
  # insert the 2 required variables here
  name   = "db_sg"
  vcp_id = module.vpc.vcp_id
  ingress_rules = [{
    port           = 3306
    security_group = [module.websvr_sg.security_group.vcp_id]

  }]
}


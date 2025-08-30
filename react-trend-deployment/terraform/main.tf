provider "aws" {
  region = var.aws_region
}

# VPC Configuration
module "vpc" {
  source = "./vpc"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# EKS Cluster
module "eks" {
  source = "./eks"
  
  cluster_name    = "${var.project_name}-cluster"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_group_name = "${var.project_name}-node-group"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Jenkins Server
module "jenkins" {
  source = "./jenkins"
  
  instance_type   = var.jenkins_instance_type
  vpc_id          = module.vpc.vpc_id
  subnet_id       = module.vpc.public_subnet_ids[0]
  key_name        = var.key_name
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

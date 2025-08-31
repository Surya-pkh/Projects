provider "aws" {
  region = var.aws_region
}

# VPC Configuration
module "vpc" {
  source = "./vpc"
  
  project_name       = var.project_name
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
  
  project_name    = var.project_name
  instance_type   = var.jenkins_instance_type
  vpc_id          = module.vpc.vpc_id
  subnet_id       = module.vpc.public_subnet_ids[0]
  key_name        = var.key_name
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Monitoring Stack (Prometheus & Grafana)
resource "aws_instance" "monitoring" {
  ami           = var.ami_id
  instance_type = var.monitoring_instance_type
  subnet_id     = module.vpc.public_subnet_ids[0]
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/monitoring/userdata.sh", {
    prometheus_retention = var.prometheus_retention_period
    grafana_password    = var.grafana_admin_password
  })

  tags = merge(
    {
      Name = "${var.project_name}-monitoring"
    },
    var.monitoring_tags
  )
}

# Security Groups
resource "aws_security_group" "monitoring_sg" {
  name_prefix = "${var.project_name}-monitoring-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project_name}-monitoring-sg"
    },
    var.monitoring_tags
  )
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "jenkins_url" {
  description = "Jenkins access URL"
  value       = module.jenkins.jenkins_url
}

output "monitoring_instance_ip" {
  description = "Public IP of monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

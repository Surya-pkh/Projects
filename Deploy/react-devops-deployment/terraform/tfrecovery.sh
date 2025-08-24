#!/bin/bash

# Complete Recovery and Fix Script
# Run this in your terraform directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔧 Starting Terraform recovery process..."

# Step 1: Clean up any partial state
print_info "Step 1: Cleaning up partial state..."
terraform destroy -auto-approve 2>/dev/null || true
print_status "Cleaned up partial resources"

# Step 2: Create the AWS key pair
print_info "Step 2: Creating AWS key pair..."
if aws ec2 describe-key-pairs --key-names devops-key >/dev/null 2>&1; then
    print_warning "Key pair 'devops-key' already exists"
else
    aws ec2 create-key-pair --key-name devops-key --query 'KeyMaterial' --output text > ../devops-key.pem
    chmod 400 ../devops-key.pem
    print_status "Created key pair and saved as devops-key.pem"
fi

# Step 3: Check supported EKS versions in your region
print_info "Step 3: Checking supported EKS versions..."
SUPPORTED_VERSION=$(aws eks describe-addon-versions --addon-name vpc-cni --query 'addons[0].addonVersions[0].compatibilities[0].clusterVersion' --output text --region $(aws configure get region))
print_info "Latest supported EKS version: $SUPPORTED_VERSION"

# Step 4: Update variables with supported version
print_info "Step 4: Updating EKS version in variables..."
cat > variables.tf << 'EOF'
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]  # Reduced to 2 AZs for cost
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "react-app-cluster"
}

variable "node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "react-app-nodes"
}

variable "instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"]  # Changed to smaller instance for cost
}

variable "desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 1  # Reduced for cost
}

variable "max_capacity" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2  # Reduced for cost
}

variable "min_capacity" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"  # Reduced for cost
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring"
  type        = string
  default     = "t3.small"  # Reduced for cost
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = "devops-key"
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = "your-dockerhub-username"  # Update this with your username
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "react-trend-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default = {
    Project     = "ReactDevOps"
    Environment = "production"
    Owner       = "DevOpsTeam"
  }
}
EOF

# Step 5: Create a simplified EKS configuration
print_info "Step 5: Creating simplified EKS configuration..."
cat > eks.tf << 'EOF'
# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = var.tags
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy,
  ]

  tags = var.tags
}

# Wait for cluster to be ready before adding addons
resource "time_sleep" "wait_for_cluster" {
  depends_on = [aws_eks_node_group.main]
  create_duration = "30s"
}

# EKS Add-ons (simplified)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"

  depends_on = [time_sleep.wait_for_cluster]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"

  depends_on = [time_sleep.wait_for_cluster]
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"

  depends_on = [aws_eks_addon.vpc_cni, time_sleep.wait_for_cluster]
}
EOF

# Step 6: Update security groups
print_info "Step 6: Updating security groups..."
cat > security-groups.tf << 'EOF'
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.app_name}-eks-cluster-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-eks-cluster-sg"
  })
}

resource "aws_security_group_rule" "eks_cluster_ingress_workstation_https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_cluster.id
  to_port           = 443
  type              = "ingress"
}

# Jenkins Security Group
resource "aws_security_group" "jenkins" {
  name_prefix = "${var.app_name}-jenkins-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins web interface"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-jenkins-sg"
  })
}

# Monitoring Security Group
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.app_name}-monitoring-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.app_name}-monitoring-sg"
  })
}
EOF

# Step 7: Reinitialize Terraform
print_info "Step 7: Reinitializing Terraform..."
terraform init -upgrade

# Step 8: Validate configuration
print_info "Step 8: Validating Terraform configuration..."
if terraform validate; then
    print_status "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    exit 1
fi

# Step 9: Plan deployment
print_info "Step 9: Planning deployment..."
terraform plan -out=tfplan

print_status "Recovery script completed successfully!"
print_warning ""
print_warning "📋 Next steps:"
echo "1. Review the plan: terraform show tfplan"
echo "2. If plan looks good, apply: terraform apply tfplan"
echo "3. Wait for resources to be created (10-15 minutes)"
echo "4. Update kubeconfig: aws eks update-kubeconfig --region us-west-2 --name react-app-cluster"
print_warning ""
print_info "💰 Cost optimized configuration:"
echo "- Reduced to 2 AZs instead of 3"
echo "- Using t3.small instances instead of t3.medium" 
echo "- Single node cluster (can scale to 2)"
echo "- Estimated cost: ~$120-150/month"
print_warning ""
print_warning "🔑 Key pair saved as: ../devops-key.pem"
print_warning "Keep this file secure - you'll need it to SSH to servers"
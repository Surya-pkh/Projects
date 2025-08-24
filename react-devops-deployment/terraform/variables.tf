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

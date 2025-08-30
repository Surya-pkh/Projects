# Instance Configuration
variable "monitoring_instance_type" {
  description = "EC2 instance type for Monitoring server"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0735c191cf914754d"  # Amazon Linux 2 in us-west-2
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
}

# Monitoring Configuration
variable "prometheus_retention_period" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

# Tags
variable "monitoring_tags" {
  description = "Tags for monitoring resources"
  type        = map(string)
  default = {
    Environment = "production"
    Component   = "monitoring"
  }
}

# EKS Cluster outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

# VPC outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# EC2 Instance outputs
output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Jenkins server public DNS"
  value       = aws_instance.jenkins.public_dns
}

output "monitoring_public_ip" {
  description = "Monitoring server public IP"
  value       = aws_eip.monitoring.public_ip
}

output "monitoring_public_dns" {
  description = "Monitoring server public DNS"
  value       = aws_instance.monitoring.public_dns
}

# Application URLs
output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "prometheus_url" {
  description = "Prometheus web interface URL"
  value       = "http://${aws_eip.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana web interface URL"
  value       = "http://${aws_eip.monitoring.public_ip}:3000"
}

# Kubeconfig command
output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

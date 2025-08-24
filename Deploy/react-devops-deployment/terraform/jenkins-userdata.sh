#!/bin/bash
set -e

# Update system and install dependencies
yum update -y
yum install -y docker git unzip

# Install Java 11
amazon-linux-extras install java-openjdk11 -y

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins

# Start and enable services
systemctl start docker
systemctl enable docker
systemctl start jenkins
systemctl enable jenkins

# Add jenkins user to docker group
usermod -a -G docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

# Configure kubectl for EKS
mkdir -p /var/lib/jenkins/.kube
aws eks update-kubeconfig --region ${region} --name ${cluster_name} --kubeconfig /var/lib/jenkins/.kube/config
chown jenkins:jenkins /var/lib/jenkins/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Setup Jenkins workspace
mkdir -p /var/lib/jenkins/workspace
chown -R jenkins:jenkins /var/lib/jenkins

# Restart Jenkins to apply changes
systemctl restart jenkins

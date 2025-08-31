#!/bin/bash

# Update system
apt-get update -y

# Install Java 17 (required for Jenkins)
apt-get install -y openjdk-17-jdk

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | apt-key add -
echo deb https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
usermod -aG docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
mv terraform /usr/local/bin/

# Start and enable services
systemctl start jenkins
systemctl enable jenkins
systemctl start docker
systemctl enable docker

# Wait for Jenkins to start
sleep 60

# Configure Jenkins initial setup
mkdir -p /var/lib/jenkins/init.groovy.d

# Create Jenkins configuration script
cat > /var/lib/jenkins/init.groovy.d/basic-security.groovy << 'EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()

Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
EOF

# Install Jenkins plugins
cat > /var/lib/jenkins/init.groovy.d/install-plugins.groovy << 'EOF'
#!groovy

import jenkins.model.*
import hudson.PluginWrapper
import hudson.PluginManager

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

def plugins = [
    "git",
    "workflow-aggregator",
    "docker-plugin",
    "kubernetes",
    "pipeline-stage-view",
    "blueocean",
    "github",
    "docker-workflow"
]

plugins.each {
  if (!pm.getPlugin(it)) {
    def plugin = uc.getPlugin(it)
    if (plugin) {
      plugin.install()
    }
  }
}

instance.save()
EOF

# Set permissions
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

# Restart Jenkins to apply configurations
systemctl restart jenkins

# Log completion
echo "Jenkins installation completed at $(date)" >> /var/log/user-data.log

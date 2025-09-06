#!/bin/bash

# Set variables
EKS_VPC_ID="vpc-0e4ce9c9d1f247933"
EKS_SUBNET_ID="subnet-08c2208c1ddbc2a0e"  # Using the first subnet from EKS config
EKS_SECURITY_GROUP="sg-029b97cf66e756f53"  # Using the EKS security group

# Get Jenkins instance ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "🔍 Jenkins Instance ID: $INSTANCE_ID"

# Create AMI backup
echo "📸 Creating AMI backup..."
AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "jenkins-backup-$(date +%Y%m%d-%H%M%S)" \
    --description "Backup before VPC migration" \
    --no-reboot \
    --query 'ImageId' \
    --output text)
echo "✅ AMI created: $AMI_ID"

# Wait for AMI to be available
echo "⏳ Waiting for AMI to be ready..."
aws ec2 wait image-available --image-ids $AMI_ID

# Stop Jenkins service
echo "🛑 Stopping Jenkins service..."
sudo systemctl stop jenkins

# Create new network interface in EKS VPC
echo "🌐 Creating network interface in EKS VPC..."
ENI_ID=$(aws ec2 create-network-interface \
    --subnet-id $EKS_SUBNET_ID \
    --groups $EKS_SECURITY_GROUP \
    --description "Jenkins EKS Network Interface" \
    --query 'NetworkInterface.NetworkInterfaceId' \
    --output text)
echo "✅ Network Interface created: $ENI_ID"

# Wait for ENI to be available
echo "⏳ Waiting for network interface to be ready..."
aws ec2 wait network-interface-available --network-interface-ids $ENI_ID

# Attach new network interface
echo "🔌 Attaching new network interface..."
aws ec2 attach-network-interface \
    --network-interface-id $ENI_ID \
    --instance-id $INSTANCE_ID \
    --device-index 1

# Update route table
echo "🛣️ Updating route table..."
MAIN_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$EKS_VPC_ID" "Name=association.main,Values=true" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

aws ec2 create-route \
    --route-table-id $MAIN_ROUTE_TABLE_ID \
    --destination-cidr-block "0.0.0.0/0" \
    --network-interface-id $ENI_ID

# Start Jenkins service
echo "🚀 Starting Jenkins service..."
sudo systemctl start jenkins

echo "✅ Migration completed! Please verify Jenkins connectivity."
echo "💡 Note: You may need to update your DNS or IP address configurations."
echo "🔍 New network interface ID: $ENI_ID"

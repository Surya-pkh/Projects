#!/bin/bash

# Get Jenkins instance info
JENKINS_INSTANCE_ID="i-09520b34f8efdf478"
JENKINS_INFO=$(aws ec2 describe-instances --instance-ids $JENKINS_INSTANCE_ID --query 'Reservations[0].Instances[0]')
JENKINS_VPC_ID=$(echo $JENKINS_INFO | jq -r '.VpcId')
JENKINS_SECURITY_GROUP_ID=$(echo $JENKINS_INFO | jq -r '.SecurityGroups[0].GroupId')
JENKINS_PRIVATE_IP=$(echo $JENKINS_INFO | jq -r '.PrivateIpAddress')

# Get EKS cluster security group
EKS_CLUSTER_NAME="trend-app-cluster"
EKS_SECURITY_GROUP_ID="sg-029b97cf66e756f53"

echo "🔍 Found Jenkins details:"
echo "VPC ID: $JENKINS_VPC_ID"
echo "Security Group: $JENKINS_SECURITY_GROUP_ID"
echo "Private IP: $JENKINS_PRIVATE_IP"

# Add ingress rule to EKS security group to allow traffic from Jenkins
echo "🔒 Adding ingress rule to EKS security group..."
aws ec2 authorize-security-group-ingress \
    --group-id $EKS_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --source-group $JENKINS_SECURITY_GROUP_ID

# Add VPC peering if needed
echo "🌐 Creating VPC peering connection..."
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id $JENKINS_VPC_ID \
    --peer-vpc-id vpc-0e4ce9c9d1f247933 \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
    --output text)

# Accept VPC peering
echo "✅ Accepting VPC peering connection..."
aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id $PEERING_ID

# Update route tables
echo "🛣️ Updating route tables..."

# Get Jenkins VPC route table
JENKINS_ROUTE_TABLE=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$JENKINS_VPC_ID" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

# Get EKS VPC route table
EKS_ROUTE_TABLE=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=vpc-0e4ce9c9d1f247933" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

# Add routes for VPC peering
aws ec2 create-route \
    --route-table-id $JENKINS_ROUTE_TABLE \
    --destination-cidr-block "10.0.0.0/16" \
    --vpc-peering-connection-id $PEERING_ID

aws ec2 create-route \
    --route-table-id $EKS_ROUTE_TABLE \
    --destination-cidr-block "10.0.0.0/16" \
    --vpc-peering-connection-id $PEERING_ID

echo "✅ VPC peering and routing configured!"
echo "🔄 Testing connectivity..."
kubectl get nodes

echo "
✨ Setup complete! The Jenkins server should now be able to access the EKS cluster.
If you still experience issues, please check:
1. Security group rules
2. Route table configurations
3. AWS IAM permissions
"

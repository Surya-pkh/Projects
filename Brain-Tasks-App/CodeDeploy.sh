#!/bin/bash

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating CodeDeploy service role..."

# Create CodeDeploy trust policy
cat > codedeploy-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create CodeDeploy service role
aws iam create-role \
  --role-name CodeDeployServiceRole \
  --assume-role-policy-document file://codedeploy-trust-policy.json 2>/dev/null || echo "Role might already exist"

# Attach managed policy for Server deployments
aws iam attach-role-policy \
  --role-name CodeDeployServiceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

echo "Creating CodeDeploy application..."

# Delete existing application if it exists (partial creation)
aws deploy delete-application --application-name brain-tasks-app 2>/dev/null || echo "No existing application to delete"

# Create CodeDeploy application with Server platform
aws deploy create-application \
  --application-name brain-tasks-app \
  --compute-platform Server

if [ $? -eq 0 ]; then
    echo "CodeDeploy application created successfully!"
    
    echo "Creating deployment group..."
    
    # Create deployment group
    aws deploy create-deployment-group \
      --application-name brain-tasks-app \
      --deployment-group-name brain-tasks-deployment-group \
      --service-role-arn arn:aws:iam::391070786986:role/CodeDeployServiceRole \
      --deployment-config-name CodeDeployDefault.AllAtOnce \
      --ec2-tag-filters Key=Environment,Type=KEY_AND_VALUE,Value=Production
    
    echo "Deployment group created successfully!"
else
    echo "Failed to create CodeDeploy application"
    exit 1
fi

# Clean up
rm -f codedeploy-trust-policy.json
#!/bin/bash

# Create the policy
POLICY_ARN=$(aws iam create-policy \
    --policy-name jenkins-vpc-migration-policy \
    --policy-document file://jenkins-vpc-policy.json \
    --query 'Policy.Arn' \
    --output text)

# Attach the policy to the Jenkins role
aws iam attach-role-policy \
    --role-name trend-app-jenkins-role \
    --policy-arn $POLICY_ARN

echo "✅ Policy attached successfully to Jenkins role"
echo "🔄 Please wait 10-15 seconds for permissions to propagate..."
sleep 15

# Run the migration script
./migrate-jenkins.sh

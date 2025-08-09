#!/bin/bash
# Variables
CONNECTION_ARN="arn:aws:codestar-connections:us-east-1:391070786986:connection/5c99e54a-a1ea-4479-9852-c7b59dc8c232"
PIPELINE_ROLE="CodePipelineServiceRole"

# Create the inline policy
cat > codestar-use-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "$CONNECTION_ARN"
    }
  ]
}
EOF

# Attach it to the CodePipeline role
aws iam put-role-policy \
  --role-name "$PIPELINE_ROLE" \
  --policy-name "CodeStarUseConnectionPolicy" \
  --policy-document file://codestar-use-policy.json

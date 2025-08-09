#!/bin/bash
# Create Lambda execution role
cat > lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name LambdaEKSDeployRole \
  --assume-role-policy-document file://lambda-trust-policy.json

# Create Lambda permissions policy
cat > lambda-eks-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::brain-tasks-pipeline-artifacts-*/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codepipeline:PutJobSuccessResult",
        "codepipeline:PutJobFailureResult"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name LambdaEKSDeployPolicy \
  --policy-document file://lambda-eks-policy.json

aws iam attach-role-policy \
  --role-name LambdaEKSDeployRole \
  --policy-arn arn:aws:iam::391070786986:policy/LambdaEKSDeployPolicy

aws iam attach-role-policy \
  --role-name LambdaEKSDeployRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
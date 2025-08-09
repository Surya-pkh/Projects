#!/bin/bash
# Update CodeBuild role with EKS permissions
cat > codebuild-eks-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
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
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create and attach the policy
aws iam create-policy \
  --policy-name CodeBuildEKSPolicy \
  --policy-document file://codebuild-eks-policy.json

aws iam attach-role-policy \
  --role-name CodeBuildServiceRole \
  --policy-arn arn:aws:iam::391070786986:policy/CodeBuildEKSPolicy

# Update CodeBuild project with enhanced environment
aws codebuild update-project \
  --name brain-tasks-build \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_MEDIUM,privilegedMode=true \
  --service-role arn:aws:iam::391070786986:role/CodeBuildServiceRole
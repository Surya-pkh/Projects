# Create trust policy for CodePipeline
cat > codepipeline-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create CodePipeline service role
aws iam create-role \
  --role-name CodePipelineServiceRole \
  --assume-role-policy-document file://codepipeline-trust-policy.json

# Create permissions policy for CodePipeline
cat > codepipeline-permissions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketVersioning",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::brain-tasks-pipeline-artifacts-*",
        "arn:aws:s3:::brain-tasks-pipeline-artifacts-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Attach policy to role
aws iam create-policy \
  --policy-name CodePipelineServiceRolePolicy \
  --policy-document file://codepipeline-permissions-policy.json

aws iam attach-role-policy \
  --role-name CodePipelineServiceRole \
  --policy-arn arn:aws:iam::391070786986:policy/CodePipelineServiceRolePolicy
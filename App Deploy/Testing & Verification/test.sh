#!/bin/bash
set -euo pipefail

### CONFIG ###
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
PIPELINE_NAME="brain-tasks-pipeline"
PIPELINE_BUCKET="brain-tasks-pipeline-artifacts-$(date +%s)"
GITHUB_OWNER="Surya-pkh"
GITHUB_REPO="Projects"
GITHUB_BRANCH="main"   # Change if your default branch is not main
CONNECTION_NAME="brain-tasks-github-connection"
################

echo "🚀 Setting up complete CI/CD pipeline for Brain Tasks App in $AWS_REGION ($AWS_ACCOUNT_ID)"

# 1. Create S3 bucket for artifacts
echo "📦 Creating S3 bucket: $PIPELINE_BUCKET"
aws s3 mb s3://$PIPELINE_BUCKET --region $AWS_REGION
aws s3api put-bucket-versioning --bucket $PIPELINE_BUCKET \
  --versioning-configuration Status=Enabled --region $AWS_REGION

# 2. Create CodeStar connection
echo "🔗 Creating CodeStar connection..."
CONNECTION_ARN=$(aws codestar-connections create-connection \
  --provider-type GitHub \
  --connection-name $CONNECTION_NAME \
  --region $AWS_REGION \
  --query 'ConnectionArn' \
  --output text)

echo "⚠️  IMPORTANT: Authorize the GitHub connection in AWS Console:"
echo "    https://console.aws.amazon.com/codesuite/settings/connections"
echo "    Connection ARN: $CONNECTION_ARN"
read -p "Press ENTER once authorization is complete in the console..."

# 3. Create pipeline-config-final.json dynamically
cat > pipeline-config-final.json <<EOF
{
  "pipeline": {
    "name": "$PIPELINE_NAME",
    "roleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/CodePipelineServiceRole",
    "artifactStore": {
      "type": "S3",
      "location": "$PIPELINE_BUCKET"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "SourceAction",
            "actionTypeId": {
              "category": "Source",
              "owner": "AWS",
              "provider": "CodeStarSourceConnection",
              "version": "1"
            },
            "configuration": {
              "ConnectionArn": "$CONNECTION_ARN",
              "FullRepositoryId": "$GITHUB_OWNER/$GITHUB_REPO",
              "BranchName": "$GITHUB_BRANCH"
            },
            "outputArtifacts": [{ "name": "SourceOutput" }]
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "BuildAction",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "configuration": {
              "ProjectName": "brain-tasks-build"
            },
            "inputArtifacts": [{ "name": "SourceOutput" }],
            "outputArtifacts": [{ "name": "BuildOutput" }]
          }
        ]
      },
      {
        "name": "Deploy",
        "actions": [
          {
            "name": "DeployAction",
            "actionTypeId": {
              "category": "Invoke",
              "owner": "AWS",
              "provider": "Lambda",
              "version": "1"
            },
            "configuration": {
              "FunctionName": "brain-tasks-deploy"
            },
            "inputArtifacts": [{ "name": "BuildOutput" }]
          }
        ]
      }
    ]
  }
}
EOF

# 4. Create the pipeline
echo "🔧 Creating CodePipeline..."
aws codepipeline create-pipeline \
  --cli-input-json file://pipeline-config-final.json \
  --region $AWS_REGION

# 5. Start pipeline execution
echo "▶️  Starting initial pipeline execution..."
EXECUTION_ID=$(aws codepipeline start-pipeline-execution \
  --name "$PIPELINE_NAME" \
  --region $AWS_REGION \
  --query 'pipelineExecutionId' \
  --output text)
echo "🚀 Pipeline started with Execution ID: $EXECUTION_ID"

# 6. Show pipeline status
echo "📊 Current pipeline state:"
aws codepipeline get-pipeline-state \
  --name "$PIPELINE_NAME" \
  --region $AWS_REGION

# 7. Show execution details
echo "🔍 Execution details:"
aws codepipeline get-pipeline-execution \
  --pipeline-name "$PIPELINE_NAME" \
  --pipeline-execution-id "$EXECUTION_ID" \
  --region $AWS_REGION

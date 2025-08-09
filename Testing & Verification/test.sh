#!/bin/bash
set -euo pipefail

PIPELINE_NAME="brain-tasks-pipeline"

echo "🔍 Searching for pipeline '$PIPELINE_NAME' across all AWS regions..."

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Get list of all AWS regions
ALL_REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

FOUND_REGION=""

for region in $ALL_REGIONS; do
    PIPELINES=$(aws codepipeline list-pipelines --region "$region" --query "pipelines[].name" --output text)
    if echo "$PIPELINES" | grep -qw "$PIPELINE_NAME"; then
        FOUND_REGION="$region"
        break
    fi
done

if [ -z "$FOUND_REGION" ]; then
    echo "❌ ERROR: Pipeline '$PIPELINE_NAME' not found in ANY region for account $ACCOUNT_ID."
    echo "💡 Check AWS Console to verify the pipeline name and account."
    exit 1
fi

echo "✅ Pipeline '$PIPELINE_NAME' found in region: $FOUND_REGION (Account: $ACCOUNT_ID)"

# Start pipeline execution
EXECUTION_ID=$(aws codepipeline start-pipeline-execution \
    --name "$PIPELINE_NAME" \
    --region "$FOUND_REGION" \
    --query 'pipelineExecutionId' \
    --output text)

echo "🚀 Pipeline started. Execution ID: $EXECUTION_ID"

# Show pipeline state
echo "📊 Current pipeline state:"
aws codepipeline get-pipeline-state --name "$PIPELINE_NAME" --region "$FOUND_REGION"

# Show execution details
echo "🔍 Execution details:"
aws codepipeline get-pipeline-execution \
    --pipeline-name "$PIPELINE_NAME" \
    --pipeline-execution-id "$EXECUTION_ID" \
    --region "$FOUND_REGION"

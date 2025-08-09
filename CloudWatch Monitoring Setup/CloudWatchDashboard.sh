#!/bin/bash
# ==========================================================
# CloudWatch Dashboard Creation Script
# Author: Surya
# Purpose: Create a monitoring dashboard for Brain Tasks App
# ==========================================================

AWS_REGION="us-east-1"
DASHBOARD_NAME="BrainTasksApp-Pipeline"

echo "[INFO] Creating CloudWatch dashboard: $DASHBOARD_NAME in $AWS_REGION..."

cat > dashboard-config.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/CodePipeline", "PipelineExecutionSuccess", "PipelineName", "brain-tasks-pipeline" ],
          [ "AWS/CodePipeline", "PipelineExecutionFailure", "PipelineName", "brain-tasks-pipeline" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$AWS_REGION",
        "title": "Pipeline Execution Status",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/CodeBuild", "BuildsSucceeded", "ProjectName", "brain-tasks-build" ],
          [ "AWS/CodeBuild", "BuildsFailed", "ProjectName", "brain-tasks-build" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$AWS_REGION",
        "title": "CodeBuild Executions",
        "period": 300
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE '/aws/lambda/brain-tasks-deploy'\\n| fields @timestamp, @message\\n| sort @timestamp desc\\n| limit 100",
        "region": "$AWS_REGION",
        "title": "Lambda Deployment Logs",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 12,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE '/aws/eks/brain-tasks-app'\\n| fields @timestamp, @message\\n| filter @message like /ERROR/ or @message like /WARN/\\n| sort @timestamp desc\\n| limit 50",
        "region": "$AWS_REGION",
        "title": "Application Error Logs",
        "view": "table"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
  --dashboard-name "$DASHBOARD_NAME" \
  --dashboard-body file://dashboard-config.json \
  --region "$AWS_REGION"

if [ $? -eq 0 ]; then
  echo "[SUCCESS] Dashboard $DASHBOARD_NAME created successfully in $AWS_REGION"
else
  echo "[ERROR] Failed to create dashboard"
fi

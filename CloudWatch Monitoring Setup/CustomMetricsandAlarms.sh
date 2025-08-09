#!/bin/bash
# ==========================================================
# CloudWatch Alarm Creation Script
# Author: Surya
# Purpose: Create alarms for pipeline, build, and Lambda errors
# ==========================================================

AWS_REGION="us-east-1"

echo "[INFO] Creating CloudWatch alarms in $AWS_REGION..."

# Alarm 1: Pipeline Failure
aws cloudwatch put-metric-alarm \
  --region $AWS_REGION \
  --alarm-name "BrainTasks-PipelineFailure" \
  --alarm-description "Alert when pipeline fails" \
  --metric-name ExecutionFailed \
  --namespace AWS/CodePipeline \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=PipelineName,Value=brain-tasks-pipeline \
  --evaluation-periods 1

# Alarm 2: CodeBuild Failure
aws cloudwatch put-metric-alarm \
  --region $AWS_REGION \
  --alarm-name "BrainTasks-BuildFailure" \
  --alarm-description "Alert when build fails" \
  --metric-name BuildsFailed \
  --namespace AWS/CodeBuild \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=ProjectName,Value=brain-tasks-build \
  --evaluation-periods 1

# Alarm 3: Lambda Function Errors
aws cloudwatch put-metric-alarm \
  --region $AWS_REGION \
  --alarm-name "BrainTasks-LambdaErrors" \
  --alarm-description "Alert when Lambda deployment fails" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=FunctionName,Value=brain-tasks-deploy \
  --evaluation-periods 1

echo "[SUCCESS] All CloudWatch alarms created successfully in $AWS_REGION."

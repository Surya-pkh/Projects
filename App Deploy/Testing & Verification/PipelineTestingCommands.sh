#!/bin/bash
# Start pipeline execution
aws codepipeline start-pipeline-execution \
  --name brain-tasks-pipeline

# Check pipeline status
aws codepipeline get-pipeline-state \
  --name brain-tasks-pipeline

# Check specific execution
EXECUTION_ID=$(aws codepipeline list-pipeline-executions \
  --pipeline-name brain-tasks-pipeline \
  --query 'pipelineExecutionSummaries[0].pipelineExecutionId' \
  --output text)

aws codepipeline get-pipeline-execution \
  --pipeline-name brain-tasks-pipeline \
  --pipeline-execution-id $EXECUTION_ID
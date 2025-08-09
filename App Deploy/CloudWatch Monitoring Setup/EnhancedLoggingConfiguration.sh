#!/bin/bash
# Create CloudWatch log groups
aws logs create-log-group --log-group-name /aws/codebuild/brain-tasks-build
aws logs create-log-group --log-group-name /aws/codepipeline/brain-tasks-pipeline
aws logs create-log-group --log-group-name /aws/lambda/brain-tasks-deploy
aws logs create-log-group --log-group-name /aws/eks/brain-tasks-app

# Set log retention
aws logs put-retention-policy --log-group-name /aws/codebuild/brain-tasks-build --retention-in-days 30
aws logs put-retention-policy --log-group-name /aws/codepipeline/brain-tasks-pipeline --retention-in-days 30
aws logs put-retention-policy --log-group-name /aws/lambda/brain-tasks-deploy --retention-in-days 30
aws logs put-retention-policy --log-group-name /aws/eks/brain-tasks-app --retention-in-days 7
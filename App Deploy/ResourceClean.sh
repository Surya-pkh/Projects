#!/bin/bash

# AWS EKS Environment Cleanup Script
# This script will delete all resources created for the Brain Tasks App deployment
# WARNING: This will permanently delete all resources - ensure you have backups if needed

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
CLUSTER_NAME="brain-tasks-cluster"
ECR_REPO="brain-tasks-app"
PIPELINE_NAME="brain-tasks-pipeline"
CODEBUILD_PROJECT="brain-tasks-build"
LAMBDA_FUNCTION="brain-tasks-deploy"

echo -e "${BLUE}🧹 Starting AWS EKS Environment Cleanup${NC}"
echo -e "${YELLOW}⚠️  WARNING: This will permanently delete all resources!${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ Cleanup cancelled${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Starting cleanup process...${NC}"

# Function to check if AWS CLI is configured
check_aws_config() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not configured or credentials invalid${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ AWS credentials verified${NC}"
}

# Function to delete Kubernetes resources
cleanup_k8s_resources() {
    echo -e "${BLUE}🔄 Cleaning up Kubernetes resources...${NC}"
    
    # Check if kubectl is configured for our cluster
    if kubectl config current-context | grep -q "$CLUSTER_NAME"; then
        echo -e "${GREEN}✅ kubectl configured for cluster: $CLUSTER_NAME${NC}"
        
        # Delete application deployment and service
        kubectl delete deployment brain-tasks-app --ignore-not-found=true
        kubectl delete service brain-tasks-service --ignore-not-found=true
        
        # Delete Fluent Bit resources if they exist
        kubectl delete daemonset fluent-bit -n amazon-cloudwatch --ignore-not-found=true
        kubectl delete configmap fluent-bit-config -n amazon-cloudwatch --ignore-not-found=true
        kubectl delete serviceaccount fluent-bit -n amazon-cloudwatch --ignore-not-found=true
        kubectl delete clusterrole fluent-bit-read --ignore-not-found=true
        kubectl delete clusterrolebinding fluent-bit-read --ignore-not-found=true
        kubectl delete namespace amazon-cloudwatch --ignore-not-found=true
        
        echo -e "${GREEN}✅ Kubernetes resources deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  kubectl not configured for cluster, skipping K8s resource cleanup${NC}"
    fi
}

# Function to delete EKS cluster
cleanup_eks_cluster() {
    echo -e "${BLUE}🔄 Deleting EKS cluster...${NC}"
    
    # Check if cluster exists
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
        echo -e "${YELLOW}⏳ Deleting EKS cluster: $CLUSTER_NAME (this may take 15-20 minutes)${NC}"
        
        # Delete the cluster using eksctl (this also deletes node groups and associated resources)
        eksctl delete cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --wait
        
        echo -e "${GREEN}✅ EKS cluster deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  EKS cluster $CLUSTER_NAME not found or already deleted${NC}"
    fi
}

# Function to delete CodePipeline
cleanup_codepipeline() {
    echo -e "${BLUE}🔄 Deleting CodePipeline...${NC}"
    
    if aws codepipeline get-pipeline --name "$PIPELINE_NAME" --region "$AWS_REGION" &> /dev/null; then
        # Stop any running executions first
        aws codepipeline stop-pipeline-execution \
            --pipeline-name "$PIPELINE_NAME" \
            --pipeline-execution-id "$(aws codepipeline list-pipeline-executions \
                --pipeline-name "$PIPELINE_NAME" \
                --query 'pipelineExecutionSummaries[0].pipelineExecutionId' \
                --output text)" \
            --abandon --region "$AWS_REGION" 2>/dev/null || true
        
        # Delete the pipeline
        aws codepipeline delete-pipeline --name "$PIPELINE_NAME" --region "$AWS_REGION"
        echo -e "${GREEN}✅ CodePipeline deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  CodePipeline $PIPELINE_NAME not found${NC}"
    fi
}

# Function to delete CodeBuild project
cleanup_codebuild() {
    echo -e "${BLUE}🔄 Deleting CodeBuild project...${NC}"
    
    if aws codebuild batch-get-projects --names "$CODEBUILD_PROJECT" --region "$AWS_REGION" &> /dev/null; then
        aws codebuild delete-project --name "$CODEBUILD_PROJECT" --region "$AWS_REGION"
        echo -e "${GREEN}✅ CodeBuild project deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  CodeBuild project $CODEBUILD_PROJECT not found${NC}"
    fi
}

# Function to delete Lambda function
cleanup_lambda() {
    echo -e "${BLUE}🔄 Deleting Lambda function...${NC}"
    
    if aws lambda get-function --function-name "$LAMBDA_FUNCTION" --region "$AWS_REGION" &> /dev/null; then
        aws lambda delete-function --function-name "$LAMBDA_FUNCTION" --region "$AWS_REGION"
        echo -e "${GREEN}✅ Lambda function deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  Lambda function $LAMBDA_FUNCTION not found${NC}"
    fi
}

# Function to clean up ECR repository
cleanup_ecr() {
    echo -e "${BLUE}🔄 Cleaning up ECR repository...${NC}"
    
    if aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" &> /dev/null; then
        # Delete all images first
        IMAGE_IDS=$(aws ecr list-images --repository-name "$ECR_REPO" --region "$AWS_REGION" --query 'imageIds[*]' --output json)
        if [ "$IMAGE_IDS" != "[]" ]; then
            aws ecr batch-delete-image \
                --repository-name "$ECR_REPO" \
                --image-ids "$IMAGE_IDS" \
                --region "$AWS_REGION" > /dev/null
        fi
        
        # Delete the repository
        aws ecr delete-repository --repository-name "$ECR_REPO" --force --region "$AWS_REGION"
        echo -e "${GREEN}✅ ECR repository deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  ECR repository $ECR_REPO not found${NC}"
    fi
}

# Function to delete S3 bucket for pipeline artifacts
cleanup_s3_buckets() {
    echo -e "${BLUE}🔄 Deleting S3 pipeline artifacts buckets...${NC}"
    
    # Find buckets with brain-tasks-pipeline-artifacts prefix
    BUCKETS=$(aws s3 ls | grep "brain-tasks-pipeline-artifacts" | awk '{print $3}' || true)
    
    if [ -n "$BUCKETS" ]; then
        for BUCKET in $BUCKETS; do
            echo -e "${YELLOW}⏳ Emptying and deleting bucket: $BUCKET${NC}"
            # Empty the bucket first
            aws s3 rm s3://$BUCKET --recursive 2>/dev/null || true
            # Delete all versions if versioning is enabled
            aws s3api delete-objects --bucket "$BUCKET" \
                --delete "$(aws s3api list-object-versions \
                    --bucket "$BUCKET" \
                    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
                    --output json)" 2>/dev/null || true
            # Delete delete markers
            aws s3api delete-objects --bucket "$BUCKET" \
                --delete "$(aws s3api list-object-versions \
                    --bucket "$BUCKET" \
                    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
                    --output json)" 2>/dev/null || true
            # Delete the bucket
            aws s3 rb s3://$BUCKET --force 2>/dev/null || true
        done
        echo -e "${GREEN}✅ S3 buckets deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  No pipeline artifacts buckets found${NC}"
    fi
}

# Function to delete CloudWatch resources
cleanup_cloudwatch() {
    echo -e "${BLUE}🔄 Cleaning up CloudWatch resources...${NC}"
    
    # Delete dashboards
    if aws cloudwatch list-dashboards --region "$AWS_REGION" | grep -q "BrainTasksApp-Pipeline"; then
        aws cloudwatch delete-dashboards --dashboard-names "BrainTasksApp-Pipeline" --region "$AWS_REGION"
        echo -e "${GREEN}✅ CloudWatch dashboard deleted${NC}"
    fi
    
    # Delete alarms
    ALARMS=("BrainTasks-PipelineFailure" "BrainTasks-BuildFailure" "BrainTasks-LambdaErrors")
    for ALARM in "${ALARMS[@]}"; do
        if aws cloudwatch describe-alarms --alarm-names "$ALARM" --region "$AWS_REGION" | grep -q "AlarmName"; then
            aws cloudwatch delete-alarms --alarm-names "$ALARM" --region "$AWS_REGION"
            echo -e "${GREEN}✅ CloudWatch alarm $ALARM deleted${NC}"
        fi
    done
    
    # Delete log groups
    LOG_GROUPS=(
        "/aws/codebuild/brain-tasks-build"
        "/aws/codepipeline/brain-tasks-pipeline"
        "/aws/lambda/brain-tasks-deploy"
        "/aws/eks/brain-tasks-app"
        "/aws/eks/brain-tasks-cluster/cluster"
    )
    
    for LOG_GROUP in "${LOG_GROUPS[@]}"; do
        if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$AWS_REGION" | grep -q "logGroupName"; then
            aws logs delete-log-group --log-group-name "$LOG_GROUP" --region "$AWS_REGION" 2>/dev/null || true
            echo -e "${GREEN}✅ Log group $LOG_GROUP deleted${NC}"
        fi
    done
}

# Function to delete IAM roles and policies
cleanup_iam() {
    echo -e "${BLUE}🔄 Cleaning up IAM roles and policies...${NC}"
    
    # IAM roles to delete
    IAM_ROLES=(
        "CodePipelineServiceRole"
        "CodeBuildServiceRole" 
        "LambdaEKSDeployRole"
    )
    
    # Custom policies to delete
    CUSTOM_POLICIES=(
        "CodePipelineServiceRolePolicy"
        "CodeBuildEKSPolicy"
        "LambdaEKSDeployPolicy"
    )
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Detach and delete custom policies, then delete roles
    for ROLE in "${IAM_ROLES[@]}"; do
        if aws iam get-role --role-name "$ROLE" &> /dev/null; then
            # Detach all attached policies
            ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn' --output text)
            for POLICY_ARN in $ATTACHED_POLICIES; do
                aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN"
            done
            
            # Delete inline policies if any
            INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames' --output text)
            for POLICY_NAME in $INLINE_POLICIES; do
                aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY_NAME"
            done
            
            # Delete the role
            aws iam delete-role --role-name "$ROLE"
            echo -e "${GREEN}✅ IAM role $ROLE deleted${NC}"
        fi
    done
    
    # Delete custom policies
    for POLICY in "${CUSTOM_POLICIES[@]}"; do
        POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY}"
        if aws iam get-policy --policy-arn "$POLICY_ARN" &> /dev/null; then
            # Delete all policy versions except the default one
            VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?!IsDefaultVersion].VersionId' --output text)
            for VERSION in $VERSIONS; do
                aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION"
            done
            
            # Delete the policy
            aws iam delete-policy --policy-arn "$POLICY_ARN"
            echo -e "${GREEN}✅ IAM policy $POLICY deleted${NC}"
        fi
    done
}

# Function to delete CodeStar connections
cleanup_codestar_connections() {
    echo -e "${BLUE}🔄 Cleaning up CodeStar connections...${NC}"
    
    # Find connections with brain-tasks in the name
    CONNECTIONS=$(aws codestar-connections list-connections --region "$AWS_REGION" --query 'Connections[?contains(ConnectionName, `brain-tasks`)].ConnectionArn' --output text)
    
    for CONNECTION_ARN in $CONNECTIONS; do
        if [ -n "$CONNECTION_ARN" ]; then
            aws codestar-connections delete-connection --connection-arn "$CONNECTION_ARN" --region "$AWS_REGION"
            echo -e "${GREEN}✅ CodeStar connection deleted${NC}"
        fi
    done
    
    if [ -z "$CONNECTIONS" ]; then
        echo -e "${YELLOW}⚠️  No brain-tasks CodeStar connections found${NC}"
    fi
}

# Function to clean up any remaining resources
cleanup_remaining_resources() {
    echo -e "${BLUE}🔄 Checking for any remaining resources...${NC}"
    
    # Check for any remaining Load Balancers
    LBS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancers[?contains(LoadBalancerName, `brain-tasks`) || contains(DNSName, `brain-tasks`)].LoadBalancerArn' --output text)
    for LB_ARN in $LBS; do
        if [ -n "$LB_ARN" ]; then
            aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$AWS_REGION"
            echo -e "${GREEN}✅ Load Balancer deleted${NC}"
        fi
    done
    
    # Check for any remaining Security Groups (EKS may create some)
    echo -e "${YELLOW}ℹ️  Note: Some EKS-created security groups may still exist but should be cleaned up automatically${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}Starting cleanup process...${NC}"
    
    check_aws_config
    
    # Cleanup in order (dependencies first)
    cleanup_k8s_resources
    cleanup_codepipeline
    cleanup_codebuild
    cleanup_lambda
    cleanup_eks_cluster  # This takes the longest
    cleanup_ecr
    cleanup_s3_buckets
    cleanup_cloudwatch
    cleanup_iam
    cleanup_codestar_connections
    cleanup_remaining_resources
    
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
    echo -e "${BLUE}💡 Summary of deleted resources:${NC}"
    echo -e "   • EKS Cluster: $CLUSTER_NAME"
    echo -e "   • CodePipeline: $PIPELINE_NAME"
    echo -e "   • CodeBuild Project: $CODEBUILD_PROJECT"
    echo -e "   • Lambda Function: $LAMBDA_FUNCTION"
    echo -e "   • ECR Repository: $ECR_REPO"
    echo -e "   • S3 Pipeline Artifacts Buckets"
    echo -e "   • CloudWatch Dashboards, Alarms, and Log Groups"
    echo -e "   • IAM Roles and Policies"
    echo -e "   • CodeStar Connections"
    echo -e ""
    echo -e "${GREEN}✅ Your AWS account should no longer incur charges for these resources.${NC}"
    echo -e "${YELLOW}💰 Note: It may take a few minutes for billing to reflect the changes.${NC}"
}

# Error handling
trap 'echo -e "${RED}❌ Error occurred during cleanup. Please check AWS console for any remaining resources.${NC}"' ERR

# Run main function
main

echo -e "${BLUE}🔍 Would you like to verify the cleanup by checking for any remaining resources? (y/n):${NC}"
read -p "" verify

if [ "$verify" = "y" ] || [ "$verify" = "yes" ]; then
    echo -e "${BLUE}🔍 Verification Report:${NC}"
    
    # Check EKS
    if aws eks list-clusters --region "$AWS_REGION" --query "clusters[?contains(@, '$CLUSTER_NAME')]" --output text | grep -q "$CLUSTER_NAME"; then
        echo -e "${RED}⚠️  EKS cluster still exists${NC}"
    else
        echo -e "${GREEN}✅ EKS cluster deleted${NC}"
    fi
    
    # Check ECR
    if aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" &> /dev/null; then
        echo -e "${RED}⚠️  ECR repository still exists${NC}"
    else
        echo -e "${GREEN}✅ ECR repository deleted${NC}"
    fi
    
    # Check CodePipeline
    if aws codepipeline get-pipeline --name "$PIPELINE_NAME" --region "$AWS_REGION" &> /dev/null; then
        echo -e "${RED}⚠️  CodePipeline still exists${NC}"
    else
        echo -e "${GREEN}✅ CodePipeline deleted${NC}"
    fi
    
    # Check Lambda
    if aws lambda get-function --function-name "$LAMBDA_FUNCTION" --region "$AWS_REGION" &> /dev/null; then
        echo -e "${RED}⚠️  Lambda function still exists${NC}"
    else
        echo -e "${GREEN}✅ Lambda function deleted${NC}"
    fi
    
    echo -e "${GREEN}🎯 Verification complete!${NC}"
fi
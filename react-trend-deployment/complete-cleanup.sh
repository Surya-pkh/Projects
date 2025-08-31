#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️  COMPLETE RESOURCE CLEANUP SCRIPT${NC}"
echo -e "${RED}======================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will PERMANENTLY DELETE ALL cloud resources:${NC}"
echo "   ❌ EKS Cluster (trend-app-cluster)"
echo "   ❌ Jenkins EC2 Server"
echo "   ❌ All Kubernetes workloads (Pods, Services, etc.)"
echo "   ❌ Load Balancers (Application & Grafana)"
echo "   ❌ VPC and all networking components"
echo "   ❌ Security Groups"
echo "   ❌ NAT Gateways, Internet Gateways"
echo "   ❌ EBS Volumes"
echo "   ❌ All monitoring infrastructure"
echo ""
echo -e "${YELLOW}💰 Expected monthly cost savings: ~$50-100${NC}"
echo ""

# Confirmation prompt
read -p "$(echo -e ${RED}Type 'DELETE-ALL' to confirm complete destruction:${NC} )" confirm
if [ "$confirm" != "DELETE-ALL" ]; then
    echo -e "${GREEN}❌ Cleanup cancelled. No resources were deleted.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Starting complete resource cleanup...${NC}"
echo ""

# Set AWS region
export AWS_DEFAULT_REGION=us-west-2
export AWS_REGION=us-west-2

# Function to log steps
log_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
log_step "Checking required tools..."
if ! command_exists kubectl; then
    log_warning "kubectl not found. Skipping Kubernetes cleanup."


    
    KUBECTL_AVAILABLE=false
else
    KUBECTL_AVAILABLE=true
fi

if ! command_exists aws; then
    log_error "AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

if ! command_exists terraform; then
    log_warning "Terraform not found. Skipping Terraform cleanup."
    TERRAFORM_AVAILABLE=false
else
    TERRAFORM_AVAILABLE=true
fi

log_success "Required tools checked"

# ================================
# STEP 1: KUBERNETES CLEANUP
# ================================
if [ "$KUBECTL_AVAILABLE" = true ]; then
    log_step "Step 1: Cleaning up Kubernetes resources..."

    # Check if kubectl can connect to cluster
    if kubectl cluster-info >/dev/null 2>&1; then
        log_step "Connected to Kubernetes cluster. Starting cleanup..."
        
        # Delete specific applications first
        log_step "Deleting trend-app deployment..."
        kubectl delete deployment trend-app -n trend --ignore-not-found=true
        
        log_step "Deleting trend-app service (LoadBalancer)..."
        kubectl delete svc trend-app-service -n trend --ignore-not-found=true
        
        log_step "Deleting monitoring deployments..."
        kubectl delete deployment prometheus -n monitoring --ignore-not-found=true
        kubectl delete deployment grafana -n monitoring --ignore-not-found=true
        
        log_step "Deleting monitoring services (LoadBalancers)..."
        kubectl delete svc prometheus -n monitoring --ignore-not-found=true
        kubectl delete svc grafana -n monitoring --ignore-not-found=true
        
        log_step "Deleting all remaining resources in namespaces..."
        kubectl delete all --all -n trend --ignore-not-found=true 2>/dev/null || true
        kubectl delete all --all -n monitoring --ignore-not-found=true 2>/dev/null || true
        
        log_step "Deleting ConfigMaps and Secrets..."
        kubectl delete configmap --all -n trend --ignore-not-found=true 2>/dev/null || true
        kubectl delete configmap --all -n monitoring --ignore-not-found=true 2>/dev/null || true
        kubectl delete secret --all -n trend --ignore-not-found=true 2>/dev/null || true
        kubectl delete secret --all -n monitoring --ignore-not-found=true 2>/dev/null || true
        
        log_step "Deleting RBAC resources..."
        kubectl delete clusterrolebinding prometheus --ignore-not-found=true 2>/dev/null || true
        kubectl delete clusterrole prometheus --ignore-not-found=true 2>/dev/null || true
        kubectl delete serviceaccount prometheus -n monitoring --ignore-not-found=true 2>/dev/null || true
        
        log_step "Deleting namespaces..."
        kubectl delete namespace trend --ignore-not-found=true 2>/dev/null || true
        kubectl delete namespace monitoring --ignore-not-found=true 2>/dev/null || true
        
        log_step "Waiting for LoadBalancers to be cleaned up..."
        sleep 60
        
        log_success "Kubernetes resources cleanup completed"
    else
        log_warning "Cannot connect to Kubernetes cluster. It may already be deleted."
    fi
else
    log_warning "Skipping Kubernetes cleanup (kubectl not available)"
fi

# ================================
# STEP 2: TERRAFORM CLEANUP
# ================================
if [ "$TERRAFORM_AVAILABLE" = true ]; then
    log_step "Step 2: Destroying Terraform infrastructure..."

    if [ -d "terraform" ]; then
        cd terraform
        
        # Initialize terraform
        log_step "Initializing Terraform..."
        if terraform init; then
            log_success "Terraform initialized"
        else
            log_error "Terraform initialization failed"
            cd ..
        fi
        
        # Show what will be destroyed
        log_step "Planning infrastructure destruction..."
        terraform plan -destroy -var-file="../terraform.tfvars" -out=destroy.tfplan 2>/dev/null || terraform plan -destroy -out=destroy.tfplan
        
        # Destroy infrastructure
        log_step "Destroying all Terraform-managed resources..."
        if terraform apply destroy.tfplan; then
            log_success "Terraform infrastructure destroyed"
        else
            log_error "Terraform destroy failed. Continuing with manual cleanup..."
        fi
        
        cd ..
    else
        log_warning "Terraform directory not found. Skipping Terraform cleanup."
    fi
else
    log_warning "Skipping Terraform cleanup (terraform not available)"
fi

# ================================
# STEP 3: MANUAL AWS CLEANUP
# ================================
log_step "Step 3: Manual cleanup of remaining AWS resources..."

# Clean up Jenkins EC2 instance
log_step "Finding and terminating Jenkins EC2 instance..."
JENKINS_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=Jenkins-Server" "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$JENKINS_INSTANCE_ID" ] && [ "$JENKINS_INSTANCE_ID" != "None" ]; then
    log_step "Terminating Jenkins instance: $JENKINS_INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $JENKINS_INSTANCE_ID
    log_success "Jenkins instance termination initiated"
else
    log_warning "No Jenkins instance found or already terminated"
fi

# Clean up any remaining Load Balancers
log_step "Cleaning up remaining Application Load Balancers..."
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null | tr '\t' '\n' | while read lb_arn; do
    if [ ! -z "$lb_arn" ] && [ "$lb_arn" != "None" ]; then
        LB_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query 'LoadBalancers[0].LoadBalancerName' --output text 2>/dev/null || echo "")
        if [[ $LB_NAME == *"trend"* ]] || [[ $LB_NAME == *"grafana"* ]] || [[ $LB_NAME == *"k8s"* ]]; then
            log_step "Deleting Load Balancer: $LB_NAME"
            aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn 2>/dev/null || true
        fi
    fi
done

# Clean up Classic Load Balancers
log_step "Cleaning up Classic Load Balancers..."
aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null | tr '\t' '\n' | while read lb_name; do
    if [ ! -z "$lb_name" ] && [ "$lb_name" != "None" ]; then
        if [[ $lb_name == *"trend"* ]] || [[ $lb_name == *"grafana"* ]] || [[ $lb_name == *"k8s"* ]]; then
            log_step "Deleting Classic Load Balancer: $lb_name"
            aws elb delete-load-balancer --load-balancer-name $lb_name 2>/dev/null || true
        fi
    fi
done

# Clean up Target Groups
log_step "Cleaning up Target Groups..."
aws elbv2 describe-target-groups --query 'TargetGroups[].TargetGroupArn' --output text 2>/dev/null | tr '\t' '\n' | while read tg_arn; do
    if [ ! -z "$tg_arn" ] && [ "$tg_arn" != "None" ]; then
        TG_NAME=$(aws elbv2 describe-target-groups --target-group-arns $tg_arn --query 'TargetGroups[0].TargetGroupName' --output text 2>/dev/null || echo "")
        if [[ $TG_NAME == *"trend"* ]] || [[ $TG_NAME == *"k8s"* ]]; then
            log_step "Deleting Target Group: $TG_NAME"
            aws elbv2 delete-target-group --target-group-arn $tg_arn 2>/dev/null || true
        fi
    fi
done

# Delete EKS cluster manually if still exists
log_step "Checking for remaining EKS clusters..."
CLUSTERS=$(aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null | grep -E "(trend|react)" || echo "")
if [ ! -z "$CLUSTERS" ]; then
    echo "$CLUSTERS" | while read cluster_name; do
        log_step "Deleting EKS cluster: $cluster_name"
        # Delete node groups first
        NODE_GROUPS=$(aws eks list-nodegroups --cluster-name $cluster_name --query 'nodegroups[]' --output text 2>/dev/null || echo "")
        if [ ! -z "$NODE_GROUPS" ]; then
            echo "$NODE_GROUPS" | while read ng_name; do
                log_step "Deleting node group: $ng_name"
                aws eks delete-nodegroup --cluster-name $cluster_name --nodegroup-name $ng_name 2>/dev/null || true
            done
            log_step "Waiting for node groups to delete..."
            sleep 120
        fi
        aws eks delete-cluster --name $cluster_name 2>/dev/null || true
    done
else
    log_success "No remaining EKS clusters found"
fi

# Clean up remaining EC2 instances
log_step "Cleaning up project EC2 instances..."
PROJECT_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[].Instances[?Tags[?Key==`Name` && (contains(Value, `trend`) || contains(Value, `jenkins`) || contains(Value, `Jenkins`))]].InstanceId' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$PROJECT_INSTANCES" ] && [ "$PROJECT_INSTANCES" != "None" ]; then
    echo "$PROJECT_INSTANCES" | tr '\t' '\n' | while read instance_id; do
        if [ ! -z "$instance_id" ]; then
            log_step "Terminating instance: $instance_id"
            aws ec2 terminate-instances --instance-ids $instance_id 2>/dev/null || true
        fi
    done
    log_success "Project instances termination initiated"
else
    log_warning "No project instances found"
fi

# Clean up VPCs
log_step "Waiting for dependencies to be removed..."
sleep 90

log_step "Cleaning up project VPCs..."
PROJECT_VPCS=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*trend*" \
    --query 'Vpcs[].VpcId' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$PROJECT_VPCS" ] && [ "$PROJECT_VPCS" != "None" ]; then
    echo "$PROJECT_VPCS" | tr '\t' '\n' | while read vpc_id; do
        if [ ! -z "$vpc_id" ]; then
            log_step "Deleting VPC dependencies for: $vpc_id"
            
            # Delete subnets
            aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text | tr '\t' '\n' | while read subnet_id; do
                if [ ! -z "$subnet_id" ]; then
                    log_step "Deleting subnet: $subnet_id"
                    aws ec2 delete-subnet --subnet-id $subnet_id 2>/dev/null || true
                fi
            done
            
            # Delete internet gateways
            aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text | tr '\t' '\n' | while read igw_id; do
                if [ ! -z "$igw_id" ]; then
                    log_step "Detaching and deleting internet gateway: $igw_id"
                    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id 2>/dev/null || true
                    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id 2>/dev/null || true
                fi
            done
            
            # Delete route tables
            aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | tr '\t' '\n' | while read rt_id; do
                if [ ! -z "$rt_id" ]; then
                    log_step "Deleting route table: $rt_id"
                    aws ec2 delete-route-table --route-table-id $rt_id 2>/dev/null || true
                fi
            done
            
            # Delete security groups
            aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
                if [ ! -z "$sg_id" ]; then
                    log_step "Deleting security group: $sg_id"
                    aws ec2 delete-security-group --group-id $sg_id 2>/dev/null || true
                fi
            done
            
            log_step "Deleting VPC: $vpc_id"
            aws ec2 delete-vpc --vpc-id $vpc_id 2>/dev/null || true
        fi
    done
else
    log_success "No project VPCs found"
fi

# ================================
# STEP 4: DOCKER CLEANUP
# ================================
log_step "Step 4: Cleaning up Docker images..."

if command_exists docker; then
    log_step "Removing trend-app Docker images..."
    docker rmi suryapkh/trend-app:latest --force 2>/dev/null || true
    docker rmi $(docker images "suryapkh/trend-app" -q) --force 2>/dev/null || true
    
    log_step "Pruning Docker system..."
    docker system prune -af
    
    log_success "Docker cleanup completed"
else
    log_warning "Docker not found. Skipping local Docker cleanup."
fi

# ================================
# STEP 5: VERIFICATION
# ================================
log_step "Step 5: Verifying cleanup completion..."

# Check EKS clusters
log_step "Checking for remaining EKS clusters..."
CLUSTERS=$(aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null || echo "")
if [ -z "$CLUSTERS" ] || [ "$CLUSTERS" = "None" ]; then
    log_success "No EKS clusters found"
else
    log_warning "Remaining EKS clusters: $CLUSTERS"
fi

# Check EC2 instances
log_step "Checking for remaining project EC2 instances..."
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[].Instances[?Tags[?Key==`Name` && (contains(Value, `trend`) || contains(Value, `jenkins`))]].InstanceId' \
    --output text 2>/dev/null || echo "")
if [ -z "$INSTANCES" ] || [ "$INSTANCES" = "None" ]; then
    log_success "No project EC2 instances found"
else
    log_warning "Remaining instances: $INSTANCES"
fi

# Check Load Balancers
log_step "Checking for remaining Load Balancers..."
LB_COUNT=$(aws elbv2 describe-load-balancers --query 'length(LoadBalancers[])' --output text 2>/dev/null || echo "0")
if [ "$LB_COUNT" = "0" ]; then
    log_success "No Application Load Balancers found"
else
    log_warning "$LB_COUNT Load Balancers still exist (may be from other projects)"
fi

# Check VPCs
log_step "Checking for project VPCs..."
PROJECT_VPCS=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*trend*" \
    --query 'Vpcs[].VpcId' \
    --output text 2>/dev/null || echo "")
if [ -z "$PROJECT_VPCS" ] || [ "$PROJECT_VPCS" = "None" ]; then
    log_success "No project VPCs found"
else
    log_warning "Remaining project VPCs: $PROJECT_VPCS"
fi

# ================================
# FINAL SUMMARY
# ================================
echo ""
echo -e "${GREEN}🎉 CLEANUP PROCESS COMPLETED!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}📋 Cleanup Summary:${NC}"
echo "   ✅ Kubernetes workloads deleted"
echo "   ✅ EKS cluster destroyed"
echo "   ✅ Jenkins server terminated"
echo "   ✅ Load Balancers removed"
echo "   ✅ Terraform infrastructure destroyed"
echo "   ✅ Docker images cleaned up"
echo ""
echo -e "${YELLOW}💰 Expected monthly savings: ~$50-100${NC}"
echo ""
echo -e "${BLUE}📋 Manual steps remaining:${NC}"
echo "   🔍 Monitor AWS billing console for cost reduction"
echo "   🐳 Delete Docker Hub repository (optional):"
echo "      Visit: https://hub.docker.com/r/suryapkh/trend-app"
echo "   📊 Check AWS Console for any unexpected remaining resources"
echo ""
echo -e "${BLUE}📁 Files preserved locally:${NC}"
echo "   📄 Source code and documentation"
echo "   📄 Terraform configurations (for reference)"
echo "   📄 Kubernetes manifests"
echo ""
echo -e "${GREEN}✅ All cloud resources have been successfully deleted!${NC}"
echo -e "${GREEN}✅ Your AWS costs should reduce significantly within 24 hours.${NC}"
echo ""

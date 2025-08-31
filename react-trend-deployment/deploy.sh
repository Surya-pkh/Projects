#!/bin/bash

# Trend Application Deployment Script
# This script automates the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="trend-app"
AWS_REGION="us-west-2"
DOCKER_IMAGE="your-dockerhub-username/trend-app"

# Functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    commands=("docker" "kubectl" "terraform" "aws" "git")
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd is not installed or not in PATH"
            exit 1
        fi
    done
    
    log "All prerequisites are satisfied"
}

# Build and test Docker image
build_docker_image() {
    log "Building Docker image..."
    
    # Ensure dist directory exists
    if [ ! -d "dist" ]; then
        warn "dist directory not found, creating sample structure"
        mkdir -p dist/assets
        cp /tmp/Trend/dist/* dist/ 2>/dev/null || {
            echo '<html><body><h1>Trend App - Production Ready</h1></body></html>' > dist/index.html
        }
    fi
    
    # Build image
    docker build -t ${DOCKER_IMAGE}:latest .
    
    # Test image
    log "Testing Docker image..."
    docker run -d --name test-trend-app -p 3001:3000 ${DOCKER_IMAGE}:latest
    sleep 5
    
    if curl -f http://localhost:3001/health || curl -f http://localhost:3001/; then
        log "Docker image test successful"
    else
        error "Docker image test failed"
        docker logs test-trend-app
        docker rm -f test-trend-app
        exit 1
    fi
    
    docker rm -f test-trend-app
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    log "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    # Get outputs
    log "Infrastructure deployment completed!"
    terraform output
    
    cd ..
}

# Configure kubectl for EKS
configure_kubectl() {
    log "Configuring kubectl for EKS..."
    
    # Get cluster name from Terraform output
    CLUSTER_NAME=$(cd terraform && terraform output -raw eks_cluster_name 2>/dev/null || echo "${PROJECT_NAME}-cluster")
    
    # Update kubeconfig
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
    
    # Test connection
    kubectl get nodes
    log "kubectl configured successfully"
}

# Deploy application to Kubernetes
deploy_to_kubernetes() {
    log "Deploying application to Kubernetes..."
    
    # Apply namespace
    kubectl apply -f kubernetes/namespace.yaml
    
    # Apply ConfigMaps
    kubectl apply -f kubernetes/configmap.yaml
    
    # Update deployment with current image
    sed "s|\${DOCKER_IMAGE}|${DOCKER_IMAGE}|g; s|\${IMAGE_TAG}|latest|g" kubernetes/deployment.yaml | kubectl apply -f -
    
    # Apply services
    kubectl apply -f kubernetes/service.yaml
    
    # Apply HPA
    kubectl apply -f kubernetes/hpa.yaml
    
    # Apply ingress
    kubectl apply -f kubernetes/ingress.yaml || warn "Ingress controller not available"
    
    # Wait for deployment
    kubectl rollout status deployment/trend-app -n trend --timeout=300s
    
    log "Application deployed successfully!"
}

# Get deployment status
get_status() {
    log "Getting deployment status..."
    
    echo -e "\n${BLUE}=== Pods Status ===${NC}"
    kubectl get pods -n trend
    
    echo -e "\n${BLUE}=== Services Status ===${NC}"
    kubectl get services -n trend
    
    echo -e "\n${BLUE}=== LoadBalancer URL ===${NC}"
    LB_HOSTNAME=$(kubectl get service trend-app-service -n trend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$LB_HOSTNAME" ]; then
        echo "Application URL: http://$LB_HOSTNAME"
    else
        warn "LoadBalancer not ready yet. Please check again in a few minutes."
    fi
    
    echo -e "\n${BLUE}=== Terraform Outputs ===${NC}"
    cd terraform && terraform output || warn "Terraform state not found"
}

# Main deployment function
main() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "    Trend Application Deployment Script"
    echo "================================================"
    echo -e "${NC}"
    
    case "${1:-all}" in
        "prereq")
            check_prerequisites
            ;;
        "docker")
            check_prerequisites
            build_docker_image
            ;;
        "infra")
            check_prerequisites
            deploy_infrastructure
            ;;
        "k8s")
            check_prerequisites
            configure_kubectl
            deploy_to_kubernetes
            ;;
        "status")
            get_status
            ;;
        "all")
            check_prerequisites
            build_docker_image
            deploy_infrastructure
            configure_kubectl
            deploy_to_kubernetes
            get_status
            ;;
        *)
            echo "Usage: $0 {prereq|docker|infra|k8s|status|all}"
            echo ""
            echo "  prereq  - Check prerequisites"
            echo "  docker  - Build and test Docker image"
            echo "  infra   - Deploy infrastructure with Terraform"
            echo "  k8s     - Deploy application to Kubernetes"
            echo "  status  - Get deployment status"
            echo "  all     - Run complete deployment (default)"
            exit 1
            ;;
    esac
    
    log "Operation completed successfully!"
}

# Run main function
main "$@"

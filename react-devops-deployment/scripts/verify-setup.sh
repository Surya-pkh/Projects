#!/bin/bash

# Verify Setup Script

set -e

echo "🔍 Verifying setup..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}✅ $1 service is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 service is not running${NC}"
        return 1
    fi
}

echo "🔧 Checking required tools..."
check_command "docker"
check_command "kubectl"
check_command "terraform"
check_command "aws"
check_command "git"

echo ""
echo "🔧 Checking Docker..."
if docker info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is not running${NC}"
fi

echo ""
echo "🔧 Checking AWS CLI configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${GREEN}✅ AWS CLI is configured${NC}"
    aws sts get-caller-identity
else
    echo -e "${RED}❌ AWS CLI is not configured${NC}"
fi

echo ""
echo "🔧 Checking Kubernetes cluster connection..."
if kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${GREEN}✅ kubectl is configured and cluster is accessible${NC}"
    kubectl cluster-info
else
    echo -e "${YELLOW}⚠️  kubectl is not configured or cluster is not accessible${NC}"
fi

echo ""
echo "🔧 Checking Terraform..."
if [ -d "terraform" ]; then
    cd terraform
    if terraform validate > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
    else
        echo -e "${RED}❌ Terraform configuration is invalid${NC}"
        terraform validate
    fi
    cd ..
else
    echo -e "${YELLOW}⚠️  Terraform directory not found${NC}"
fi

echo ""
echo "🔧 Checking project structure..."
required_dirs=("app" "terraform" "kubernetes" "jenkins" "monitoring" "scripts" "docs")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $dir directory exists${NC}"
    else
        echo -e "${RED}❌ $dir directory missing${NC}"
    fi
done

echo ""
echo "🎯 Verification completed!"

#!/bin/bash

# Cleanup Resources Script

set -e

echo "🧹 Cleaning up resources..."

# Confirm before proceeding
read -p "⚠️  This will destroy ALL resources. Are you sure? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "❌ Cleanup cancelled."
    exit 0
fi

# Clean up Kubernetes resources
echo "🗑️  Cleaning up Kubernetes resources..."
if kubectl get namespace react-app > /dev/null 2>&1; then
    kubectl delete namespace react-app
    echo "✅ Kubernetes resources cleaned up"
fi

# Clean up Terraform resources
echo "🗑️  Cleaning up Terraform infrastructure..."
if [ -d "terraform" ]; then
    cd terraform
    if [ -f "terraform.tfstate" ]; then
        terraform destroy -auto-approve
        echo "✅ Terraform resources destroyed"
    else
        echo "ℹ️  No Terraform state found"
    fi
    cd ..
fi

# Clean up Docker images
echo "🗑️  Cleaning up Docker images..."
docker system prune -f
docker image prune -a -f

echo "✅ Cleanup completed!"
echo "💡 Remember to:"
echo "   - Delete DockerHub repository if no longer needed"
echo "   - Remove AWS CLI credentials if temporary"
echo "   - Delete SSH keys if created for this project"

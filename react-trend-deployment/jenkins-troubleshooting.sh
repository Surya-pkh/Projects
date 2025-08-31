#!/bin/bash

echo "🔍 Jenkins Pipeline Troubleshooting Guide"
echo "========================================"
echo ""

# Function to check credential
check_credential() {
    local cred_id=$1
    local cred_name=$2
    
    echo "Checking $cred_name credential ($cred_id)..."
    
    # This is a simplified check - in reality, Jenkins API would be used
    if curl -s -u admin:admin123 "http://54.68.35.10:8080/credentials/store/system/domain/_/credential/$cred_id/" | grep -q "404"; then
        echo "❌ $cred_name credential NOT found"
        echo "   → Create credential with ID: $cred_id"
        return 1
    else
        echo "✅ $cred_name credential exists"
        return 0
    fi
}

echo "🔧 Common Pipeline Issues & Solutions:"
echo "======================================="
echo ""

echo "1. Credential Issues:"
echo "   Problem: Pipeline fails with 'credentials not found'"
echo "   Solution: Verify credential IDs match exactly:"
echo "   - aws-credentials (for AWS access)"
echo "   - docker-hub-credentials (for Docker Hub)"
echo ""

echo "2. Repository Issues:"
echo "   Problem: 'Unable to find Jenkinsfile'"
echo "   Solution: Verify these settings:"
echo "   - Repository URL: https://github.com/Surya-pkh/Projects.git"
echo "   - Script Path: react-trend-deployment/Jenkinsfile"
echo "   - Branch: */main"
echo ""

echo "3. Docker Build Issues:"
echo "   Problem: Docker build fails"
echo "   Solution: Check if files exist in repo:"
ls -la /home/Projects/react-trend-deployment/Dockerfile /home/Projects/react-trend-deployment/nginx.conf /home/Projects/react-trend-deployment/dist/ 2>/dev/null | head -5
echo ""

echo "4. EKS Access Issues:"
echo "   Problem: kubectl commands fail"
echo "   Solution: Verify AWS credentials and EKS access"
echo "   Current EKS status:"
kubectl get nodes --no-headers 2>/dev/null | head -2 | awk '{print "   " $1 " - " $2}' || echo "   ❌ EKS not accessible"
echo ""

echo "5. Docker Hub Push Issues:"
echo "   Problem: Push denied"
echo "   Solution: Verify Docker Hub credentials"
echo "   Test: docker login -u suryapkh"
echo ""

echo "📋 Pipeline Configuration Checklist:"
echo "===================================="
echo "✅ Jenkins accessible: http://54.68.35.10:8080"
echo "✅ Repository exists: https://github.com/Surya-pkh/Projects.git"
echo "✅ Jenkinsfile path: react-trend-deployment/Jenkinsfile"
echo "□ AWS credentials configured (aws-credentials)"
echo "□ Docker Hub credentials configured (docker-hub-credentials)"
echo "□ Pipeline job created and configured"
echo ""

echo "🚀 Test Your Setup:"
echo "=================="
echo "1. Go to Jenkins → Your Pipeline Job"
echo "2. Click 'Build Now'"
echo "3. Watch 'Console Output' for progress"
echo "4. Check each stage completes successfully"
echo ""

echo "📞 If Issues Persist:"
echo "===================="
echo "1. Check Jenkins logs: Manage Jenkins → System Log"
echo "2. Verify credential IDs match pipeline exactly"
echo "3. Test manual Docker build: cd react-trend-deployment && docker build -t test ."
echo "4. Test kubectl access: kubectl get pods -n trend"
echo ""

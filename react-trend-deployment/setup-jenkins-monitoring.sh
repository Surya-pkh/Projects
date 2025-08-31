#!/bin/bash

# Setup script for Jenkins and Monitoring configuration
# Run this after infrastructure deployment

echo "🚀 Setting up Jenkins and Monitoring for Trend Application"
echo "========================================================="

# Get infrastructure details
JENKINS_IP=$(terraform output -raw jenkins_url | cut -d'/' -f3 | cut -d':' -f1)
MONITORING_IP=$(terraform output -raw monitoring_instance_ip)
EKS_CLUSTER=$(terraform output -raw eks_cluster_name)

echo "📊 Infrastructure Details:"
echo "Jenkins URL: http://${JENKINS_IP}:8080"
echo "Prometheus URL: http://${MONITORING_IP}:9090"
echo "Grafana URL: http://${MONITORING_IP}:3000"
echo "EKS Cluster: ${EKS_CLUSTER}"
echo ""

# Configure kubectl for EKS
echo "🔧 Configuring kubectl for EKS..."
aws eks update-kubeconfig --name ${EKS_CLUSTER} --region us-west-2

echo "✅ kubectl configured for EKS cluster"

# Deploy monitoring namespace and resources
echo "📈 Setting up Kubernetes monitoring..."
kubectl apply -f kubernetes/monitoring.yaml

echo "✅ Monitoring resources deployed to Kubernetes"

# Check Jenkins status
echo "🔍 Checking Jenkins status..."
curl -s http://${JENKINS_IP}:8080 > /dev/null && echo "✅ Jenkins is accessible" || echo "❌ Jenkins is not accessible yet"

# Check Prometheus status
echo "🔍 Checking Prometheus status..."
curl -s http://${MONITORING_IP}:9090 > /dev/null && echo "✅ Prometheus is accessible" || echo "❌ Prometheus is not accessible yet"

# Check Grafana status
echo "🔍 Checking Grafana status..."
curl -s http://${MONITORING_IP}:3000 > /dev/null && echo "✅ Grafana is accessible" || echo "❌ Grafana is not accessible yet"

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo ""
echo "1. 🔐 JENKINS SETUP:"
echo "   • Open: http://${JENKINS_IP}:8080"
echo "   • Login with: admin / admin123"
echo "   • Install suggested plugins"
echo "   • Configure Docker Hub credentials (ID: docker-hub-credentials)"
echo "   • Configure AWS credentials for EKS access"
echo "   • Create a new pipeline job using the Jenkinsfile"
echo ""
echo "2. 📊 GRAFANA SETUP:"
echo "   • Open: http://${MONITORING_IP}:3000"
echo "   • Login with: admin / admin123"
echo "   • Add Prometheus data source: http://localhost:9090"
echo "   • Import dashboard from: monitoring/grafana-dashboard.json"
echo ""
echo "3. 📈 PROMETHEUS TARGETS:"
echo "   • Open: http://${MONITORING_IP}:9090/targets"
echo "   • Verify Kubernetes targets are discovered"
echo ""
echo "4. 🚀 CI/CD PIPELINE:"
echo "   • Create Jenkins job using the Jenkinsfile"
echo "   • Configure webhook in GitHub repository"
echo "   • Test the pipeline by triggering a build"
echo ""

# Create Jenkins credentials helper script
cat > jenkins-credentials-helper.sh << 'EOF'
#!/bin/bash
echo "Setting up Jenkins credentials..."

# Docker Hub credentials setup
echo "1. Add Docker Hub Credentials:"
echo "   - Go to Jenkins > Manage Jenkins > Credentials"
echo "   - Click 'Global' domain"
echo "   - Add Credentials > Username with password"
echo "   - ID: docker-hub-credentials"
echo "   - Username: suryapkh"
echo "   - Password: [your-docker-hub-password]"
echo ""

# AWS credentials setup
echo "2. Add AWS Credentials:"
echo "   - Add Credentials > AWS Credentials"
echo "   - ID: aws-credentials"
echo "   - Access Key ID: [your-aws-access-key]"
echo "   - Secret Access Key: [your-aws-secret-key]"
echo ""

# Kubeconfig setup
echo "3. Add Kubeconfig:"
echo "   - Add Credentials > Secret file"
echo "   - ID: kubeconfig-file"
echo "   - File: Upload your ~/.kube/config file"
echo ""
EOF

chmod +x jenkins-credentials-helper.sh

echo "💡 HELPFUL COMMANDS:"
echo "==================="
echo ""
echo "# Check application status"
echo "kubectl get pods -n trend"
echo "kubectl get svc -n trend"
echo ""
echo "# View application logs"
echo "kubectl logs -f deployment/trend-app -n trend"
echo ""
echo "# Check monitoring targets"
echo "curl http://${MONITORING_IP}:9090/api/v1/targets"
echo ""
echo "# Scale application"
echo "kubectl scale deployment trend-app --replicas=5 -n trend"
echo ""

echo "🎉 Setup script completed!"
echo "Please follow the next steps above to complete the configuration."

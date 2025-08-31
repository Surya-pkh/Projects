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

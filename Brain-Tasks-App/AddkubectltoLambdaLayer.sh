# Create kubectl layer for Lambda
mkdir kubectl-layer && cd kubectl-layer
mkdir -p bin

# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl bin/

# Download AWS CLI v2 (if needed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
cp -r aws-cli/v2/current/bin/* bin/
rm -rf aws aws-cli awscliv2.zip

# Create layer zip
zip -r kubectl-layer.zip bin/

# Create Lambda layer
aws lambda publish-layer-version \
  --layer-name kubectl-layer \
  --zip-file fileb://kubectl-layer.zip \
  --compatible-runtimes python3.9 \
  --description "kubectl and AWS CLI for EKS deployments"

# Get layer ARN and attach to function
LAYER_ARN=$(aws lambda list-layer-versions --layer-name kubectl-layer --query 'LayerVersions[0].LayerVersionArn' --output text)

aws lambda update-function-configuration \
  --function-name brain-tasks-deploy \
  --layers $LAYER_ARN

cd ..
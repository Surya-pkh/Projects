#!/bin/bash
set -e

# Clean old build
rm -rf lambda-deploy
mkdir lambda-deploy && cd lambda-deploy

#####################################
# Create Lambda Function Python Code
#####################################
cat > lambda_function.py << 'EOF'
import json
import boto3
import tempfile
from kubernetes import client, config
import zipfile
import os
import base64
from botocore.signers import RequestSigner

def lambda_handler(event, context):
    codepipeline = boto3.client('codepipeline')
    s3 = boto3.client('s3')

    try:
        job_id = event['CodePipeline.job']['id']
        input_artifacts = event['CodePipeline.job']['data']['inputArtifacts']

        if not input_artifacts:
            raise Exception("No input artifacts found")

        location = input_artifacts[0]['location']['s3Location']
        bucket = location['bucketName']
        key = location['objectKey']

        with tempfile.NamedTemporaryFile() as tmp_file:
            s3.download_file(bucket, key, tmp_file.name)

            with tempfile.TemporaryDirectory() as tmp_dir:
                with zipfile.ZipFile(tmp_file.name, 'r') as zip_ref:
                    zip_ref.extractall(tmp_dir)

                image_def_path = os.path.join(tmp_dir, 'imagedefinitions.json')
                if not os.path.exists(image_def_path):
                    raise Exception("imagedefinitions.json not found")

                with open(image_def_path, 'r') as f:
                    image_definitions = json.load(f)

                image_uri = image_definitions[0]['imageUri']
                print(f"Deploying image: {image_uri}")

                if update_eks_deployment(image_uri):
                    codepipeline.put_job_success_result(jobId=job_id)
                    return {"statusCode": 200, "body": "Deployment successful"}
                else:
                    raise Exception("EKS deployment failed")

    except Exception as e:
        print(f"Error: {str(e)}")
        codepipeline.put_job_failure_result(
            jobId=job_id,
            failureDetails={'message': str(e), 'type': 'JobFailed'}
        )
        return {"statusCode": 500, "body": f"Error: {str(e)}"}


def get_eks_token(cluster_name, region):
    session = boto3.session.Session()
    client = session.client('eks', region_name=region)
    service_id = client.meta.service_model.service_id

    signer = RequestSigner(
        service_id,
        region,
        'sts',
        'v4',
        session.get_credentials(),
        session.events
    )

    params = {
        'method': 'GET',
        'url': 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15',
        'body': {},
        'headers': {'x-k8s-aws-id': cluster_name},
        'context': {}
    }

    signed_url = signer.generate_presigned_url(
        params,
        region_name=region,
        expires_in=60,
        operation_name=''
    )

    return 'k8s-aws-v1.' + base64.urlsafe_b64encode(signed_url.encode()).decode().rstrip('=')


def update_eks_deployment(image_uri):
    try:
        region = "us-east-1"
        cluster_name = "brain-tasks-cluster"
        namespace = "default"
        deployment_name = "brain-tasks-app"

        eks = boto3.client('eks', region_name=region)
        cluster_info = eks.describe_cluster(name=cluster_name)['cluster']

        # Configure Kubernetes client directly
        configuration = client.Configuration()
        configuration.host = cluster_info['endpoint']
        configuration.verify_ssl = True
        configuration.ssl_ca_cert = tempfile.NamedTemporaryFile(delete=False).name
        with open(configuration.ssl_ca_cert, 'w') as f:
            f.write(base64.b64decode(cluster_info['certificateAuthority']['data']).decode())

        token = get_eks_token(cluster_name, region)
        configuration.api_key = {"authorization": "Bearer " + token}

        client.Configuration.set_default(configuration)

        # Patch deployment image
        apps_v1 = client.AppsV1Api()
        deployment = apps_v1.read_namespaced_deployment(deployment_name, namespace)
        deployment.spec.template.spec.containers[0].image = image_uri
        apps_v1.patch_namespaced_deployment(deployment_name, namespace, deployment)

        print(f"Updated deployment {deployment_name} with image {image_uri}")
        return True

    except Exception as e:
        print(f"Error updating EKS: {e}")
        return False
EOF

#####################################
# Create requirements.txt
#####################################
cat > requirements.txt << 'EOF'
boto3==1.26.137
kubernetes==26.1.0
EOF

#####################################
# Install dependencies into folder
#####################################
pip install -r requirements.txt --target .

#####################################
# Package Lambda function
#####################################
zip -r brain-tasks-deploy.zip .

#####################################
# Deploy Lambda function
#####################################
aws lambda create-function \
  --function-name brain-tasks-deploy \
  --runtime python3.9 \
  --role arn:aws:iam::391070786986:role/LambdaEKSDeployRole \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://brain-tasks-deploy.zip \
  --timeout 300 \
  --memory-size 512 \
  || aws lambda update-function-code \
       --function-name brain-tasks-deploy \
       --zip-file fileb://brain-tasks-deploy.zip

echo "✅ Lambda function deployed successfully"
cd ..

import json
import boto3
import base64
import subprocess
import os
import tempfile
import zipfile
from urllib.parse import urlparse

def lambda_handler(event, context):
    # Initialize clients
    codepipeline = boto3.client('codepipeline')
    s3 = boto3.client('s3')
    
    try:
        # Get job details
        job_id = event['CodePipeline.job']['id']
        input_artifacts = event['CodePipeline.job']['data']['inputArtifacts']
        
        # Download build artifacts
        if input_artifacts:
            location = input_artifacts[0]['location']['s3Location']
            bucket = location['bucketName']
            key = location['objectKey']
            
            # Download and extract artifacts
            with tempfile.NamedTemporaryFile() as tmp_file:
                s3.download_file(bucket, key, tmp_file.name)
                
                with tempfile.TemporaryDirectory() as tmp_dir:
                    with zipfile.ZipFile(tmp_file.name, 'r') as zip_ref:
                        zip_ref.extractall(tmp_dir)
                    
                    # Read image definitions
                    image_def_path = os.path.join(tmp_dir, 'imagedefinitions.json')
                    if os.path.exists(image_def_path):
                        with open(image_def_path, 'r') as f:
                            image_definitions = json.load(f)
                        
                        # Update Kubernetes deployment
                        result = update_eks_deployment(image_definitions[0]['imageUri'])
                        
                        if result:
                            codepipeline.put_job_success_result(jobId=job_id)
                            return {'statusCode': 200, 'body': 'Deployment successful'}
                        else:
                            raise Exception('EKS deployment failed')
                    else:
                        raise Exception('imagedefinitions.json not found')
        
        else:
            raise Exception('No input artifacts found')
            
    except Exception as e:
        print(f'Error: {str(e)}')
        codepipeline.put_job_failure_result(
            jobId=job_id,
            failureDetails={'message': str(e), 'type': 'JobFailed'}
        )
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

def update_eks_deployment(image_uri):
    try:
        # Configure kubectl
        os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
        
        # Update kubeconfig
        subprocess.run([
            'aws', 'eks', 'update-kubeconfig', 
            '--region', 'us-east-1', 
            '--name', 'brain-tasks-cluster'
        ], check=True)
        
        # Update deployment image
        subprocess.run([
            'kubectl', 'set', 'image', 
            'deployment/brain-tasks-app', 
            f'brain-tasks-app={image_uri}'
        ], check=True)
        
        # Wait for rollout to complete
        subprocess.run([
            'kubectl', 'rollout', 'status', 
            'deployment/brain-tasks-app', 
            '--timeout=300s'
        ], check=True)
        
        print(f'Successfully deployed image: {image_uri}')
        return True
        
    except subprocess.CalledProcessError as e:
        print(f'kubectl command failed: {e}')
        return False
    except Exception as e:
        print(f'Deployment error: {e}')
        return False

import json
import boto3
import tempfile
import yaml
from kubernetes import client, config
import zipfile
import os

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


def update_eks_deployment(image_uri):
    try:
        region = "us-east-1"
        cluster_name = "brain-tasks-cluster"
        namespace = "default"
        deployment_name = "brain-tasks-app"

        eks = boto3.client('eks', region_name=region)
        cluster_info = eks.describe_cluster(name=cluster_name)['cluster']

        # Create kubeconfig dynamically
        kubeconfig = {
            "apiVersion": "v1",
            "clusters": [{
                "cluster": {
                    "server": cluster_info['endpoint'],
                    "certificate-authority-data": cluster_info['certificateAuthority']['data']
                },
                "name": "cluster"
            }],
            "contexts": [{
                "context": {
                    "cluster": "cluster",
                    "user": "aws"
                },
                "name": "context"
            }],
            "current-context": "context",
            "kind": "Config",
            "users": [{
                "name": "aws",
                "user": {
                    "exec": {
                        "apiVersion": "client.authentication.k8s.io/v1beta1",
                        "command": "aws",
                        "args": ["eks", "get-token", "--cluster-name", cluster_name, "--region", region]
                    }
                }
            }]
        }

        # Save kubeconfig to a temp file
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_kube:
            yaml.dump(kubeconfig, tmp_kube)
            tmp_kube.flush()
            config.load_kube_config(tmp_kube.name)

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

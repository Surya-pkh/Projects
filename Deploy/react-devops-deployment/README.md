# React DevOps Deployment Project

Complete CI/CD pipeline for deploying a React application to AWS EKS using Jenkins, Docker, Terraform, and Kubernetes with Prometheus/Grafana monitoring.

## Architecture Overview

- **React Application**: Frontend application containerized with Docker
- **AWS EKS**: Managed Kubernetes cluster for container orchestration
- **Jenkins**: CI/CD pipeline automation (separate EC2 instance)
- **Monitoring**: Prometheus & Grafana for observability (separate EC2 instance)
- **Infrastructure**: Managed with Terraform

## Quick Start

1. Clone this repository
2. Update variables in `terraform/variables.tf`
3. Run the setup: `./setup.sh your-dockerhub-username`
4. Follow the deployment guide in `docs/SETUP.md`

## Project Structure

See file structure in the main documentation.

## Prerequisites

- AWS CLI configured
- Docker installed
- Terraform installed
- kubectl installed
- DockerHub account

## Deployment Steps

1. **Infrastructure Setup**: `cd terraform && terraform apply`
2. **Application Build**: `./scripts/build-and-push.sh`
3. **Kubernetes Deployment**: `./scripts/deploy-to-k8s.sh`
4. **Jenkins Setup**: Follow `docs/SETUP.md`
5. **Monitoring Setup**: Run monitoring setup on designated server

## Monitoring

- Prometheus: Metrics collection
- Grafana: Visualization dashboards
- Kubernetes metrics and application health monitoring

## CI/CD Pipeline

Jenkins pipeline includes:
- Source code checkout
- Docker image build
- Push to DockerHub
- Deploy to EKS cluster
- Run health checks

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request


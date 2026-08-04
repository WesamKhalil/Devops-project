# Devops project

Devops project ideally using Terraform, Jenkins, Docker, Kubernetes, and AWS.

This README is intentionally minimal and shows how to run the project locally and deploy infrastructure. Replace example paths and values with the real ones from this repository.

## Prerequisites

- Git
- Node.js (>=16) and npm or yarn
- Terraform (>=1.0)
- Docker
- kubectl
- AWS CLI (configured with credentials)
- (Optional) Jenkins for CI/CD

## Quick start — run locally

1. Clone the repo:

   git clone https://github.com/WesamKhalil/Devops-project.git
   cd Devops-project

2. If the app is in `app/` or `src/`:

   cd app
   npm install
   npm run build    # if TypeScript build step exists
   npm start

For development:

   npm run dev

If there is no `app` directory, run commands in the repository folder that contains the TypeScript/JavaScript code.

## Run with Docker

1. Build the image (run from repository root or the folder that contains the Dockerfile):

   docker build -t devops-project:latest .

2. Run the container:

   docker run -p 3000:3000 devops-project:latest

Adjust ports and image name as required.

## Terraform (infrastructure)

1. Change into the Terraform directory (example: `infra/`):

   cd infra

2. Initialize and apply (review plan before applying):

   terraform init
   terraform plan -out=tfplan
   terraform apply "tfplan"

Or apply directly:

   terraform apply -auto-approve

Ensure AWS credentials/region are configured (`aws configure` or environment variables).

## Kubernetes

Apply manifests from the `k8s/` directory:

   kubectl apply -f k8s/

Ensure your kubeconfig points to the correct cluster and that container images are available in a registry reachable by the cluster.

## Jenkins

If a `Jenkinsfile` exists, create a pipeline in Jenkins pointing to this repository and configure required credentials (AWS, Docker registry, etc.).

## Notes

- Replace placeholder paths and ports with the actual ones used by this repo.
- Do not commit secrets. Use environment variables, CI secret stores, or a secrets manager.

Repository: https://github.com/WesamKhalil/Devops-project

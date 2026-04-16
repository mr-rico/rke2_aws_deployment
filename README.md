# Testing for deploying RKE2 on AWS

This version replaces the original EC2-per-tier design with:

- **3 RKE2 server nodes**
- **3 RKE2 agent nodes**
- **3-tier application deployed inside Kubernetes**
  - `frontend` Deployment
  - `backend` Deployment
  - `postgres` StatefulSet
- **Public ingress** through an AWS **Network Load Balancer** that forwards `80/443` to the worker nodes running **ingress-nginx** in `hostNetwork` mode

## Architecture

- Terraform builds the AWS network, security groups, EC2 nodes, and the NLB.
- Terraform also renders `ansible/inventory.ini`.
- Ansible installs and configures RKE2.
- Kubernetes manifests deploy the application.
- The database is kept private behind a `ClusterIP` Service and a `NetworkPolicy`.
- Only the frontend is published externally through an `Ingress`.

## Layout

```text
terraform/           AWS infrastructure for a 3x3 RKE2 cluster
ansible/             RKE2 installation and app deployment
k8s/                 Kubernetes manifests
apps/frontend/       Frontend Flask app
apps/backend/        Backend Flask API
```

## Prerequisites

- Terraform >= 1.6
- Ansible >= 2.15
- kubectl installed
- helm installed
- AWS CLI installed and configured
- An SSH key pair already created in AWS
- A container registry that the cluster can pull from

## 1. Build and push images

Set a registry you control, for example GitLab Container Registry, ECR, or Docker Hub.

```bash
export REGISTRY=registry.example.com/test-registry
export TAG=$(git rev-parse --short HEAD)

docker build -t ${REGISTRY}/frontend:${TAG} apps/frontend
docker build -t ${REGISTRY}/backend:${TAG} apps/backend

docker push ${REGISTRY}/frontend:${TAG}
docker push ${REGISTRY}/backend:${TAG}
```

## 2. Provision AWS infrastructure

Create an account and issue roles for permissions:
- AmazonEC2FullAccess
- AmazonS3FullAccess
- AmazonVPCFullAccess
- ElasticLoadBalancingFullAccess


Configure AWS CLI
```bash
aws configure
```
Validate configurations
```bash
aws sts get-caller-identity
```

Create ssh key pair and adjust permissions
```bash
aws ec2 create-key-pair \
  --key-name rke2-key \
  --query 'KeyMaterial' \
  --output text > rke2-key.pem
chmod 400 rke2-key.pem
```

Create `terraform/terraform.tfvars` from the example and adjust values.
```bash
cd terraform
terraform init
# terraform plan
terraform apply -auto-approve
cd ..
```

Terraform presents output to the terminal and writes the `ansible/inventory.ini` automatically.
Append the following to the inventory.ini file:
```bash
[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=./rke2-key.pem
```

Output can be reproduced 
```bash
terraform output
```

## 3. Configure the cluster and deploy the app

Create the Ansible vault or plain vars file for the database password if you want to override the default. Then run:

```bash
# cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i ansible/inventory.ini ansible/site.yml
# ansible-playbook -i inventory.ini site.yml   -e registry=${REGISTRY}   -e image_tag=${TAG}   -e app_hostname=app.example.com
cd ..
```

## 4. Route DNS

Point your DNS record for `app.example.com` at the `nlb_dns_name` Terraform output.

## Design notes

### Why NLB + ingress-nginx hostNetwork?
RKE2 is self-managed here, not EKS. Using `ingress-nginx` as a DaemonSet in `hostNetwork` mode avoids needing the AWS cloud controller to provision a load balancer for Kubernetes services. AWS NLB stays outside the cluster and forwards raw TCP `80/443` traffic to every worker node.

### Why keep Postgres in-cluster?
You asked for the 3-tier services to live inside the cluster. If you later want stronger durability and managed backups, swap the `StatefulSet` for Amazon RDS and keep the backend Deployment unchanged.

### What is exposed publicly?
Only the frontend path through the ingress. The backend and database stay internal.

## Deployment flow

1. Terraform creates VPC, subnets, security groups, instances, and NLB.
2. Ansible installs RKE2 servers, joins agents, and writes kubeconfig locally.
3. Ansible installs ingress-nginx.
4. Ansible deploys namespace, secrets, Postgres, backend, frontend, and ingress.
5. The NLB publishes the ingress controller externally.

# EKSWebAppDeployment

![EKS](https://img.shields.io/badge/Amazon%20EKS-Cluster%20Deployment-FF9900?logo=amazon-eks&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Manifests%20%26%20Kustomize-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-Chart%20Management-0F1689?logo=helm&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerized%20App-2496ED?logo=docker&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Load%20Balancer%20Controller-FF9900?logo=amazonaws&logoColor=white)
![Autoscaler](https://img.shields.io/badge/K8s-Cluster%20Autoscaler-326CE5?logo=kubernetes&logoColor=white)
![HPA](https://img.shields.io/badge/K8s-HPA%20Enabled-326CE5?logo=kubernetes&logoColor=white)
![CI/CD](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?logo=github-actions&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-WSL2%20%7C%20Ubuntu-blue)


Production-ready GitHub repository scaffold to deploy a Docker Hub-hosted web application to **Amazon EKS** using:

* Managed nodegroups (eksctl / AWS CLI)
* AWS Load Balancer Controller (ALB ingress)
* Cluster Autoscaler (IRSA)
* Kustomize overlays for environment management
* Horizontal Pod Autoscaler (HPA)

> This repository intentionally avoids Terraform — cluster/node provisioning uses `eksctl` & `aws` CLI.


---

# 🚀 Complete Deployment Steps

A full end-to-end workflow to deploy your EKS cluster and web application.

---

## ✅ 1. Install prerequisites

```bash
make prereqs
```

This installs:

* AWS CLI
* kubectl
* eksctl
* Helm
* jq, unzip, ca-certificates

---

## ✅ 2. Create the EKS Cluster

Cluster config file:

```
templates/cluster-config.yaml
```

Create cluster:

```bash
make cluster
```

⏳ Takes 15–25 minutes.

Verify:

```bash
aws eks describe-cluster --name EKSWEBDEPLOY --region ap-south-1
```

Look for: `"status": "ACTIVE"`.

---

## ✅ 3. Update kubeconfig

```bash
make update-kubeconfig CLUSTER=EKSWEBDEPLOY REGION=ap-south-1
kubectl get nodes
```

You should see your managed nodegroup nodes.

---

## ✅ 4. Install AWS Load Balancer Controller (ALB)

Follow docs:

```
docs/alb-controller-install.md
```

This includes:

* OIDC association
* IAM policy creation
* IRSA service account
* Helm installation

Verify:

```bash
kubectl -n kube-system get deployment aws-load-balancer-controller
```

---

## ✅ 5. Install Cluster Autoscaler

```bash
./scripts/install_cluster_autoscaler.sh EKSWEBDEPLOY ap-south-1
```

Check:

```bash
kubectl -n kube-system get deployment cluster-autoscaler
```

---

## ✅ 6. Create Docker Pull Secret (Private Image Only)

```bash
make create-secret \
  DOCKER_USER=myuser \
  DOCKER_PASS=mypass \
  DOCKER_EMAIL=me@example.com
```

---

## ✅ 7. Deploy the Web Application

### Staging:

```bash
make deploy OVERLAY=manifests/overlays/staging
```

### Production:

```bash
make deploy OVERLAY=manifests/overlays/prod
```

Check pods:

```bash
kubectl get pods -n webapp
```

---

## ✅ 8. Get the ALB URL

```bash
kubectl -n webapp get ingress
```

Copy the ALB DNS name into your browser.

---

## 🧹 9. Cleanup

Delete deployed app:

```bash
make destroy OVERLAY=manifests/overlays/staging
```

Delete entire EKS cluster:

```bash
eksctl delete cluster --name EKSWEBDEPLOY --region ap-south-1
```

---

# 📁 Project Structure

```
EKSWebAppDeployment/
├── Makefile                     # Automation: deploy, destroy, prereqs, kubeconfig, secret, etc.
├── README.md                    # Full documentation & setup guide
│
├── diagrams/
│   └── architecture.mmd         # Mermaid architecture diagram for EKS deployment
│
├── docs/                        # Additional project docs
│   ├── EKS.PNG                  # EKS architecture image
│   ├── alb-controller-install.md# Step-by-step ALB controller installation
│   └── best-practices.md        # Production best practices for EKS workloads
│
├── manifests/                   # Kubernetes manifests (Kustomize structure)
│   ├── base/                    # Base YAML (Deployment, Service, HPA, Ingress, Namespace)
│   └── overlays/                # Environment overlays
│       ├── prod/                # Production overrides
│       └── staging/             # Staging overrides
│
├── mywebapp/                    # Sample Node.js application deployed on EKS
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
│
├── scripts/                     # Fully automated helper scripts
│   ├── prerequisites.sh         # Install AWS CLI, kubectl, eksctl, Helm, jq
│   ├── deploy.sh                # Deploy via Kustomize + Makefile
│   ├── destroy.sh               # Cleanup app resources
│   ├── create-image-pull-secret.sh # Private image pull secret generator
│   ├── create_nodegroup.sh      # Extra nodegroup creation
│   └── install_cluster_autoscaler.sh # Autoscaler installation with IRSA
│
└── templates/
    ├── cluster-config.yaml      # eksctl config: VPC, nodegroups, cluster settings
    └── nodegroup-config.yaml    # Optional separate nodegroup template

```

---

# 🏁 Done!

Your Amazon EKS cluster with ALB, Autoscaler, and Kustomize-based deployments is fully ready.
Additional enhancements available:

* HTTPS with ACM
* ExternalDNS (automatic Route53 DNS management)
* Spot + On-Demand mixed nodegroups
* GitHub Actions CI/CD

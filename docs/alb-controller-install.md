# === docs/alb-controller-install.md ===

````markdown
# AWS Load Balancer Controller Installation Guide

This guide describes how to install the AWS Load Balancer Controller (ALB Controller)
for your EKS cluster using **Helm + IRSA (IAM Roles for Service Accounts)** — the recommended production method.

---

## 1. Prerequisites

### ✔ EKS Cluster  
Make sure a running Amazon EKS cluster exists.

### ✔ IAM OIDC Provider Enabled  
Check:
```bash
eksctl utils associate-iam-oidc-provider --cluster <CLUSTER_NAME> --approve
````

### ✔ kubectl, eksctl, helm installed

Use:

```bash
./scripts/prerequisites.sh
```

---

## 2. Download IAM Policy for ALB Controller

AWS provides the official policy JSON:

```bash
curl -o alb-iam-policy.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

Create the AWS IAM policy:

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://alb-iam-policy.json
```

---

## 3. Create IAM Role for ServiceAccount (IRSA)

```bash
eksctl create iamserviceaccount \
  --cluster <CLUSTER_NAME> \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts
```

---

## 4. Install AWS Load Balancer Controller via Helm

Add Helm repo:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

Install:

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<CLUSTER_NAME> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<REGION>
```

---

## 5. Verify Installation

```bash
kubectl -n kube-system get deployment aws-load-balancer-controller
```

Expected output: READY 1/1.

---

## 6. ALB Controller Anatomy

* Watches `Ingress` objects with annotation `kubernetes.io/ingress.class: alb`
* Creates AWS ALBs, listeners, rules, target groups
* Supports HTTP, HTTPS, host-based & path-based routing
* Works with NodePort/ClusterIP services

---

## 7. Common ALB Ingress Annotations

```yaml
annotations:
  kubernetes.io/ingress.class: alb
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
  alb.ingress.kubernetes.io/group.name: webapp-group
```

---

## 8. Troubleshooting

| Issue              | Fix                                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------------------- |
| ALB not created    | Check controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` |
| IAM errors         | Ensure IRSA role is created and attached properly                                                           |
| Subnets not tagged | Public: `kubernetes.io/role/elb=1`, Private: `kubernetes.io/role/internal-elb=1`                            |

---

## 9. Links

* AWS: [https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
* GitHub: [https://github.com/kubernetes-sigs/aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)

````

---

# === docs/best-practices.md ===
```markdown
# Best Practices for EKS Web App Deployment

This document provides operational, security, and architectural best practices
for running a production-grade application on Amazon EKS.

---

## 1. IAM & Security

### ✔ Use IRSA Everywhere
Never store AWS access keys in pods. Assign IAM roles to Kubernetes Service Accounts.

### ✔ Least Privilege IAM Policies
Each controller (ALB, Cluster Autoscaler, ExternalDNS, etc.) gets its own policy.

### ✔ Secret Management
Use one of the following:
- AWS Secrets Manager
- SSM Parameter Store
- Sealed Secrets (for GitOps)

### ✔ Private Node Groups
Use private subnets for worker nodes in production.

---

## 2. Networking

### ✔ ALB for Ingress
- Public ALB → public subnets
- Internal ALB → private subnets

### ✔ Required Subnet Tags
Public subnets:
````

kubernetes.io/role/elb: 1

```
Private subnets:
```

kubernetes.io/role/internal-elb: 1

```

### ✔ Security Groups
Restrict nodegroups to essential ports only.

---

## 3. Autoscaling

### ✔ Horizontal Pod Autoscaler
Use CPU or memory-based HPA.

### ✔ Cluster Autoscaler
Ensure ASG/nodegroup tags:
```

k8s.io/cluster-autoscaler/enabled: "true"
k8s.io/cluster-autoscaler/<cluster-name>: "owned"

```

---

## 4. Logging & Observability

- Install **metrics-server** (required for HPA)
- Use **CloudWatch Container Insights** or **Prometheus + Grafana**
- Use FluentBit for log shipping

---

## 5. CI/CD

### ✔ GitHub Actions
Use for linting, scanning, and kustomize validation.

### ✔ GitOps (Advanced)
Use ArgoCD or FluxCD for declarative cluster deployments.

---

## 6. Cluster Upgrades

- Recommended order:
  1. Nodegroups
  2. Addons
  3. Control plane
- Blue/Green method: create new nodegroup → drain old → delete old

---

## 7. Image Best Practices

- Scan images (Trivy, Snyk)
- Use minimal base images (Alpine or Distroless)
- Keep image sizes small

---

## 8. Cost Optimization

- Right-size nodes
- Enable autoscaling
- Use Spot nodegroups in dev/staging

---

## 9. Backup & DR

- Use Velero for Kubernetes backups
- Use RDS snapshots if using managed databases

---

## 10. Documentation

- Maintain updated architecture diagrams
- Track all IAM policy changes in version control
- Keep onboarding docs for cluster and CI/CD workflows
```

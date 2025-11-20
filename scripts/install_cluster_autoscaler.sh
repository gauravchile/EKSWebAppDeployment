#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${1:-my-eks-cluster}
REGION=${2:-$(aws configure get region || echo us-east-1)}
NAMESPACE=kube-system
SA_NAME=cluster-autoscaler

echo "Checking OIDC provider..."
OIDC=$(/usr/local/bin/aws eks describe-cluster --name "$CLUSTER_NAME" \
  --region "$REGION" --query "cluster.identity.oidc.issuer" --output text)

if [[ "$OIDC" == "None" ]]; then
  echo "❌ No OIDC provider found. Run:"
  echo "eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve"
  exit 1
fi

echo "OIDC provider OK: $OIDC"

POLICY_NAME="ClusterAutoscalerPolicy-$CLUSTER_NAME"
TMP=$(mktemp)

cat > "$TMP" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ],
    "Resource": "*"
  }]
}
EOF

echo "Creating IAM policy..."
/usr/local/bin/aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://"$TMP" || true

ACC_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating IAM service account (IRSA)..."
eksctl create iamserviceaccount \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --namespace "$NAMESPACE" \
  --name "$SA_NAME" \
  --attach-policy-arn arn:aws:iam::$ACC_ID:policy/$POLICY_NAME \
  --approve

echo "Installing Cluster Autoscaler via Helm..."

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace "$NAMESPACE" \
  --set autoDiscovery.clusterName="$CLUSTER_NAME" \
  --set awsRegion="$REGION" \
  --set rbac.serviceAccount.create=false \
  --set rbac.serviceAccount.name="$SA_NAME"

echo "Cluster Autoscaler installed."
kubectl -n kube-system get pods -l app.kubernetes.io/name=cluster-autoscaler

#!/usr/bin/env bash
set -euo pipefail

NODEGROUP_NAME=${1:-webapp-ng}
CLUSTER_NAME=${2:-my-eks-cluster}
REGION=${3:-$(/usr/local/bin/aws configure get region || echo us-east-1)}

TEMPLATE=templates/nodegroup-config.yaml.template

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template not found. Using inline config."

  eksctl create nodegroup \
    --cluster "$CLUSTER_NAME" \
    --name "$NODEGROUP_NAME" \
    --region "$REGION" \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 2 \
    --nodes-max 5 \
    --managed

else
  TMP=$(mktemp)
  sed \
    -e "s/{{NODEGROUP_NAME}}/$NODEGROUP_NAME/g" \
    -e "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g" \
    -e "s/{{REGION}}/$REGION/g" \
    "$TEMPLATE" > "$TMP"

  echo "Using config:"
  cat "$TMP"

  eksctl create nodegroup -f "$TMP"
  rm -f "$TMP"
fi

echo "Nodegroup creation initiated."

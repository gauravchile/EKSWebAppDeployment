#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <docker-server> <username> <password> <email> [namespace]"
  exit 1
fi

SERVER=$1
USER=$2
PASS=$3
EMAIL=$4
NAMESPACE=${5:-webapp}
SECRET_NAME=regcred

echo "Creating namespace if missing..."
kubectl create ns "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating image pull secret..."
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="$SERVER" \
  --docker-username="$USER" \
  --docker-password="$PASS" \
  --docker-email="$EMAIL" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Image pull secret created: $SECRET_NAME in namespace $NAMESPACE"
echo "Patch service account using:"
echo "kubectl patch sa default -n $NAMESPACE -p '{\"imagePullSecrets\": [{\"name\": \"regcred\"}]}'"

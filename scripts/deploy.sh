#!/usr/bin/env bash
set -euo pipefail

OVERLAY=${1:-manifests/overlays/staging}

echo "Applying Kustomize overlay: $OVERLAY"

kubectl apply -k "$OVERLAY"

echo "Waiting for deployment rollout..."
kubectl -n webapp rollout status deployment/webapp

echo "Current service & ingress:"
kubectl -n webapp get svc,ingress

#!/usr/bin/env bash
set -euo pipefail

OVERLAY=${1:-manifests/overlays/staging}

echo "⚠ WARNING: This will delete ALL resources defined in: $OVERLAY"
read -p "Type 'yes' to continue: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

kubectl delete -k "$OVERLAY" --ignore-not-found

echo "Resources deleted (namespace webapp still exists)."

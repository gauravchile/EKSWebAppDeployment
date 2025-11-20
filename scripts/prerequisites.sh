#!/usr/bin/env bash
set -euo pipefail

echo "== Installing prerequisites for EKSWebAppDeployment =="

install_pkg() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Installing $1..."
    sudo apt-get update -y
    sudo apt-get install -y "$1"
  else
    echo "$1 already installed."
  fi
}

install_pkg curl
install_pkg unzip
install_pkg jq
install_pkg ca-certificates

# AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  echo "Installing AWS CLI v2..."
  tmp=$(mktemp -d)
  cd "$tmp"
  curl -sLO "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  #unzip awscliv2.zip
  unzip awscli-exe-linux-x86_64.zip
  sudo ./aws/install
  cd -
  rm -rf "$tmp"
fi

# kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# eksctl
if ! command -v eksctl >/dev/null 2>&1; then
  echo "Installing eksctl..."
  curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/
fi

# Helm
if ! command -v helm >/dev/null 2>&1; then
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo ""
echo "=== Prerequisites installed successfully ==="
echo "Next: Create CLuster run 'make cluster'"
echo "Next: Install ALB Controller using docs/alb-controller-install.md"

# Makefile for EKSWebAppDeployment
# Usage: make <target> [VARIABLE=value]
# Examples:
#   make prereqs
#   make create-nodegroup NODEGROUP=my-ng CLUSTER=my-cluster
#   make create-secret DOCKER_USER=me DOCKER_PASS=abc DOCKER_EMAIL=a@b.com
#   make deploy OVERLAY=manifests/overlays/prod
#   make validate
#
# Default values (override on command line or export env vars)
CLUSTER ?= my-eks-cluster
REGION  ?= us-east-1
OVERLAY ?= manifests/overlays/staging
NODEGROUP ?= webapp-ng
DOCKER_SERVER ?= https://index.docker.io/v1/
DOCKER_USER ?=
DOCKER_PASS ?=
DOCKER_EMAIL ?=
SECRET_NAME ?= regcred
TMP_PACKAGE ?= release.tar.gz

SHELL := /bin/bash
.PHONY: help prereqs update-kubeconfig create-nodegroup install-autoscaler create-secret deploy destroy validate lint zip clean rollout status

##############################################################################
## Help
##############################################################################
help:
	@sed -n '1,120p' $(MAKEFILE_LIST) | sed -n '1,120p'
	@echo
	@echo "Available targets:"
	@echo "  prereqs               - Install CLI prerequisites (awscli, kubectl, eksctl, helm) via scripts/prerequisites.sh"
	@echo "  update-kubeconfig     - Update kubeconfig for $(CLUSTER) in $(REGION)"
	@echo "  create-nodegroup      - Create a managed nodegroup (uses scripts/create_nodegroup.sh)"
	@echo "                         override NODEGROUP/CLUSTER/REGION on the make command line"
	@echo "  install-autoscaler    - Install cluster-autoscaler with IRSA (uses scripts/install_cluster_autoscaler.sh)"
	@echo "  create-secret         - Create docker-registry imagePullSecret in namespace 'webapp'"
	@echo "                         requires DOCKER_USER, DOCKER_PASS, DOCKER_EMAIL"
	@echo "  deploy                - Apply kustomize overlay (default: $(OVERLAY))"
	@echo "  destroy               - Delete kustomize overlay"
	@echo "  validate              - Validate kustomize overlays (staging & prod)"
	@echo "  lint                  - Run shellcheck on scripts/"
	@echo "  zip                   - Create compressed archive of repo (excludes .git)"
	@echo "  clean                 - Remove generated artifacts like $(TMP_PACKAGE)"
	@echo "  rollout               - Wait for rollout status of webapp deployment"
	@echo "  status                - Show service/ingress/pods in namespace webapp"
	@echo
	@echo "Examples:"
	@echo "  make prereqs"
	@echo "  make create-nodegroup NODEGROUP=webapp-ng CLUSTER=prod-cluster REGION=ap-south-1"
	@echo "  make create-secret DOCKER_USER=me DOCKER_PASS=xxx DOCKER_EMAIL=me@example.com"
	@echo

##############################################################################
## Core actions (call the scripts in scripts/)
##############################################################################

prereqs:
	@echo "== Running prerequisites installer =="
	@./scripts/prerequisites.sh

cluster:
	eksctl create cluster -f templates/cluster-config.yaml

update-kubeconfig:
	@echo "== Updating kubeconfig for cluster '$(CLUSTER)' region '$(REGION)' =="
	@aws eks update-kubeconfig --region $(REGION) --name $(CLUSTER)

create-nodegroup:
	@echo "== Creating managed nodegroup '$(NODEGROUP)' in cluster '$(CLUSTER)' =="
	@./scripts/create_nodegroup.sh $(NODEGROUP) $(CLUSTER) $(REGION)

install-autoscaler:
	@echo "== Installing Cluster Autoscaler for cluster '$(CLUSTER)' =="
	@./scripts/install_cluster_autoscaler.sh $(CLUSTER) $(REGION)

create-secret:
ifndef DOCKER_USER
	$(error DOCKER_USER is required. Example: make create-secret DOCKER_USER=me DOCKER_PASS=xxx DOCKER_EMAIL=a@b.com)
endif
ifndef DOCKER_PASS
	$(error DOCKER_PASS is required. Example: make create-secret DOCKER_USER=me DOCKER_PASS=xxx DOCKER_EMAIL=a@b.com)
endif
ifndef DOCKER_EMAIL
	$(error DOCKER_EMAIL is required. Example: make create-secret DOCKER_USER=me DOCKER_PASS=xxx DOCKER_EMAIL=a@b.com)
endif
	@echo "== Creating docker registry secret '$(SECRET_NAME)' in namespace 'webapp' =="
	@./scripts/create-image-pull-secret.sh $(DOCKER_SERVER) $(DOCKER_USER) $(DOCKER_PASS) $(DOCKER_EMAIL) webapp $(SECRET_NAME)

deploy:
	@echo "== Deploying overlay: $(OVERLAY) =="
	@./scripts/deploy.sh $(OVERLAY)

destroy:
	@echo "== Destroying resources in overlay: $(OVERLAY) =="
	@./scripts/destroy.sh $(OVERLAY)

##############################################################################
## Validation / Linting
##############################################################################

validate:
	@echo "== Validating kustomize overlays (staging & prod) =="
	@which kustomize >/dev/null 2>&1 || (echo "kustomize not found — install with 'curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/latest/download/kustomize_kustomize_$(shell uname -s)_amd64' && move to /usr/local/bin"; exit 1)
	@kustomize build manifests/overlays/staging >/dev/null
	@kustomize build manifests/overlays/prod >/dev/null
	@echo "Kustomize overlays OK."

lint:
	@echo "== Linting shell scripts with shellcheck =="
	@which shellcheck >/dev/null 2>&1 || (echo "shellcheck not found; installing..."; sudo apt-get update && sudo apt-get install -y shellcheck)
	@shellcheck scripts/*.sh

##############################################################################
## Observability helpers
##############################################################################

rollout:
	@echo "== Waiting for deployment rollout status =="
	@kubectl -n webapp rollout status deployment/webapp

status:
	@echo "== Namespace 'webapp' resources =="
	@kubectl -n webapp get pods,svc,ingress

##############################################################################
## Packaging / cleanup
##############################################################################

zip:
	@echo "== Creating $(TMP_PACKAGE) (excludes .git) =="
	@rm -f $(TMP_PACKAGE)
	@tar --exclude='.git' --exclude='node_modules' -czf $(TMP_PACKAGE) .

clean:
	@echo "== Cleaning artifacts =="
	@rm -f $(TMP_PACKAGE)

##############################################################################
## Safety / readonly
##############################################################################
.PHONY: help

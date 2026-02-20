# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-Code repository for a local Kubernetes development environment. Uses Terraform to provision a Kind (Kubernetes in Docker) cluster and deploy microservices infrastructure. The project language is Korean (comments, docs, commit messages).

## Key Commands

### Terraform (run from `environments/local/`)
```bash
cd environments/local
terraform init          # Initialize providers (kind, kubernetes, helm, kubectl)
terraform plan          # Preview infrastructure changes
terraform apply         # Create/update Kind cluster and base infrastructure
terraform destroy       # Tear down entire cluster
```

### Local Deployment Script (`environments/local/scripts/deploy-local.sh`)
```bash
./deploy-local.sh                    # Full deploy (infra + apps, builds Java & Docker images)
./deploy-local.sh --light            # Lightweight deploy (skips broker services, <2.4GB RAM)
./deploy-local.sh --apps-only        # Redeploy app services only (rebuilds Java + Docker)
./deploy-local.sh --infra-only       # Deploy infrastructure services only
./deploy-local.sh --cleanup          # Remove all resources from dev namespace
./deploy-local.sh --pause            # Scale all deployments to 0
./deploy-local.sh --resume           # Scale all deployments back to 1
./deploy-local.sh --status           # Show pods, services, memory summary, access info
```

### Cluster Inspection
```bash
kind export kubeconfig --name local-dev
kubectl get pods -n dev -o wide
kubectl get svc -n dev
kubectl -n dev logs -f deploy/<service-name>
```

## Architecture

### Two-Layer Infrastructure Provisioning

**Layer 1 — Terraform** (`environments/local/main.tf`, `argocd.tf`):
Creates the Kind cluster with port mappings, installs MetalLB (load balancer), local-path-provisioner (storage), and ArgoCD (GitOps CD). This is the foundational layer — run once.

**Layer 2 — Shell Script** (`environments/local/scripts/deploy-local.sh`):
Builds Java backend from sibling repo `mzc-final-project-be`, creates Docker images, loads them into Kind, and applies Kubernetes manifests. This is the iterative development layer — run repeatedly.

### Service Topology (all in `dev` namespace)

Infrastructure services deployed via manifests in `environments/local/manifests/dev/`:

- **3 PostgreSQL instances**: keycloak, user, booking (each independent)
- **2 Kafka instances**: auth, business (KRaft mode, no Zookeeper)
- **2 Redis instances**: auth (sessions), business (with AOF persistence)
- **MinIO**: S3-compatible object storage (TLS-enabled, self-signed certs)
- **Keycloak**: Identity provider (custom image with theme + realm import)
- **4 Spring Boot apps**: gateway-service, user-command-service, user-query-service, email-service

### Port Mapping (NodePort → Host)

| Service | NodePort | Host Port | Protocol |
|---------|----------|-----------|----------|
| Gateway | 30080 | 8080 | HTTP |
| Keycloak | 30090 | 9090 | HTTP |
| MinIO API | 30100 | 9000 | HTTPS |
| MinIO Console | 30101 | 9001 | HTTPS |
| ArgoCD | 30070 | - | HTTP |

### Configuration Split

- `configmap.yaml` — Non-sensitive env vars (hostnames, ports, endpoints)
- `secret.yaml` — Credentials (gitignored, must be created manually)
- `terraform.tfvars` — GitHub username/PAT for ArgoCD (gitignored)

## Important Conventions

- All local Docker images use `:local` tag with `imagePullPolicy: Never` (loaded via `kind load`)
- Deploy script expects backend project at `../mzc-final-project-be` relative to repo root
- Terraform state for local env is partially gitignored — `environments/local/terraform.tfstate` is ignored but root `terraform.tfstate` is tracked
- Light mode (`--light`) skips kafka-business, redis-business, postgres-booking for low-RAM systems
- MinIO TLS certs are auto-generated under `environments/local/.certs/` (gitignored) and registered in macOS keychain

## Git Workflow

- Main branch: `develop`
- Individual branches: `local/<initials>/<number>-<description>`
- Commit messages in Korean

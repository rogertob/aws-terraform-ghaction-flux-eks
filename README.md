# EKS Platform POC

This is how I would build and run EKS in production. The idea was to go beyond just getting a cluster running and actually wire everything together the way you'd need to in a real environment: GitOps, observability, secrets management, autoscaling, and CI/CD all working together from day one.

## Design decisions

A few things I was intentional about:

**Separate system and workload nodes.** Platform tooling (Flux, Karpenter, External Secrets, ALB Controller) runs on a dedicated managed node group with a taint so nothing else lands there. Workloads get their own Karpenter provisioned nodes.

**GitOps all the way down.** Everything in the cluster is declared in `gitops/` and synced by Flux. I'm not running any `kubectl apply` by hand. The cluster state lives in Git.

**One base, multiple environments.** Dev and staging share the same base Kustomize manifests. Environment-specific differences like storage sizes and cluster names are handled through overlays and Flux variable substitution, so there's no copy-pasting config between environments.

**Secrets never touch the repo.** All secrets live in AWS Secrets Manager. External Secrets Operator pulls them into the cluster at runtime. The Grafana admin password, for example, is stored in Secrets Manager and synced as a Kubernetes secret automatically.

**Automated dependency updates.** Renovate runs nightly and opens PRs to bump Helm chart versions, Terraform providers, and GitHub Actions pins.

## What's in here

**Infrastructure** built with Terraform: EKS, VPC (3 AZs), Karpenter, External Secrets Operator, AWS Load Balancer Controller, Loki S3 bucket, and all the IAM roles/policies each component needs.

**GitOps** with Flux CD: HelmReleases for every platform component, Karpenter node pools, and the apps layer. Flux bootstraps itself into the cluster during `terraform apply`.

**Observability** with the full Grafana stack: Prometheus + Alertmanager for metrics, Loki + Promtail for logs stored in S3, and Grafana as the frontend. All pinned to specific chart versions.

**CI/CD** with GitHub Actions: `hello-service` is a sample app I included to show the full delivery loop. On push to `main`, it builds a Docker image, packages a Helm chart, and pushes both to GHCR. Flux picks up the new chart version and deploys it automatically.

## Stack

| Layer | Tools |
|---|---|
| Infrastructure | Terraform, AWS EKS, VPC, IAM, S3, SQS |
| GitOps | Flux CD, Kustomize, Helm |
| Autoscaling | Karpenter |
| Observability | Prometheus, Grafana, Alertmanager, Loki, Promtail |
| Secrets | AWS Secrets Manager, External Secrets Operator |
| Ingress | AWS Load Balancer Controller |
| CI/CD | GitHub Actions, GHCR |
| Dependency updates | Renovate |

## Prerequisites

- AWS account with permissions to create EKS, VPC, IAM, S3, SQS, and Secrets Manager resources
- Terraform >= 1.9
- A GitHub PAT with `repo` read/write scope

## Deploying an environment

```bash
cd terraform/environments/dev

terraform init
terraform apply \
  -var="github_org=<your-org>" \
  -var="github_repository=<repo-name>" \
  -var="github_token=<pat>"
```

After the cluster is up, create the Grafana admin secret:

```bash
aws secretsmanager create-secret \
  --name eks-poc-dev/grafana-admin \
  --secret-string '{"username":"admin","password":"<your-password>"}' \
  --region us-east-1
```

Flux will reconcile within a few minutes and deploy everything else automatically.

## Repository structure

```
.
├── terraform/
│   ├── environments/
│   │   ├── dev/              # Dev cluster
│   │   └── staging/          # Staging cluster
│   └── modules/              # Reusable Terraform modules
│
├── gitops/
│   ├── base/                 # Shared manifests used by all clusters
│   │   ├── infrastructure/   # Karpenter, External Secrets, ALB Controller
│   │   ├── config/           # Karpenter node pools, secret store config
│   │   └── apps/             # Application manifests
│   └── clusters/
│       ├── dev/              # Dev-specific Flux config and overrides
│       └── staging/          # Staging-specific Flux config and overrides
│
├── apps/
│   └── hello-service/        # Sample Python app
│
├── charts/
│   └── hello-service/        # Helm chart for hello-service
│
└── .github/
    ├── workflows/             # CI/CD and Renovate workflows
    └── renovate.json          # Renovate dependency update config
```

## Environments

| | Dev | Staging |
|---|---|---|
| Cluster | `eks-poc-dev` | `eks-poc-staging` |
| VPC | `10.0.0.0/16` | `10.1.0.0/16` |
| Region | `us-east-1` | `us-east-1` |
| Flux path | `gitops/clusters/dev` | `gitops/clusters/staging` |

terraform {
  required_providers {
    flux = {
      source = "fluxcd/flux"
    }
    github = {
      source = "integrations/github"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path    = var.flux_target_path
  version = var.flux_version != "" ? var.flux_version : null

  embedded_manifests = true

  components_extra = [
    "image-reflector-controller",
    "image-automation-controller",
  ]

  kustomization_override = <<-EOT
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - gotk-components.yaml
    - gotk-sync.yaml
    patches:
      - patch: |
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: all
          spec:
            template:
              spec:
                tolerations:
                  - key: CriticalAddonsOnly
                    operator: Exists
                nodeSelector:
                  node-role: system
        target:
          kind: Deployment
          namespace: flux-system
    EOT
}

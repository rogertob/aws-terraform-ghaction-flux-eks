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
}

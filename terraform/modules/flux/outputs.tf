output "flux_namespace" {
  description = "Namespace where Flux controllers are installed"
  value       = "flux-system"
}

output "flux_target_path" {
  description = "Repo path Flux is watching for cluster manifests"
  value       = var.flux_target_path
}

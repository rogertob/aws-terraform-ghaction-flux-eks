resource "aws_eks_addon" "this" {
  cluster_name = var.cluster_name
  addon_name   = var.addon_name

  # Null picks the latest recommended version for the clusters k8s version automatically.
  addon_version = var.addon_version

  # Optional: structured configuration passed to the addon controller.
  configuration_values = var.configuration_values


  service_account_role_arn = var.service_account_role_arn

  dynamic "pod_identity_association" {
    for_each = var.pod_identity_associations
    content {
      service_account = pod_identity_association.value.service_account
      role_arn        = pod_identity_association.value.role_arn
    }
  }

  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.resolve_conflicts_on_update

  tags = var.tags
}

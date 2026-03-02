resource "aws_eks_access_entry" "this" {
  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  type          = var.entry_type
  tags          = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  policy_arn    = var.policy_arn

  access_scope {
    type       = var.access_scope_type
    namespaces = var.access_scope_type == "namespace" ? var.namespaces : []
  }

  lifecycle {
    precondition {
      condition     = var.access_scope_type != "namespace" || length(var.namespaces) > 0
      error_message = "namespaces must be provided when access_scope_type is 'namespace'."
    }
  }

  depends_on = [aws_eks_access_entry.this]
}

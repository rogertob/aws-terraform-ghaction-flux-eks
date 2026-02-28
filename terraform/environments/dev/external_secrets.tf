resource "aws_iam_policy" "external_secrets" {
  name        = "${local.name}-external-secrets"
  description = "Allow External Secrets Operator to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${local.name}/*"
    }]
  })

  tags = local.tags
}

module "external_secrets_pod_identity" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${local.name}-external-secrets"
  namespace       = "external-secrets"
  service_account = "external-secrets"
  policy_arns     = [aws_iam_policy.external_secrets.arn]

  tags       = local.tags
  depends_on = [module.addon_pod_identity_agent]
}

# Grafana admin credentials
resource "aws_secretsmanager_secret" "grafana_admin" {
  name        = "${local.name}/grafana-admin"
  description = "Grafana admin credentials"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = "changeme"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

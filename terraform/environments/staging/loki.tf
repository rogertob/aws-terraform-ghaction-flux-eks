resource "aws_s3_bucket" "loki" {
  bucket        = "${local.name}-loki"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket                  = aws_s3_bucket.loki.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "loki" {
  name        = "${local.name}-loki"
  description = "Allow Loki to read/write objects in its S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = "${aws_s3_bucket.loki.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.loki.arn
      },
    ]
  })

  tags = local.tags
}

module "loki_pod_identity" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${local.name}-loki"
  namespace       = "monitoring"
  service_account = "loki"
  policy_arns     = [aws_iam_policy.loki.arn]

  tags       = local.tags
  depends_on = [module.addon_pod_identity_agent]
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "association_id" {
  description = "ID of the EKS Pod Identity Association"
  value       = aws_eks_pod_identity_association.this.association_id
}

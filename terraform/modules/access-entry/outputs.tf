output "principal_arn" {
  description = "IAM ARN granted access"
  value       = aws_eks_access_entry.this.principal_arn
}

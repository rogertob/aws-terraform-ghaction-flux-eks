output "addon_name" {
  description = "Name of the installed addon"
  value       = aws_eks_addon.this.addon_name
}

output "addon_version" {
  description = "Installed addon version"
  value       = aws_eks_addon.this.addon_version
}

output "arn" {
  description = "ARN of the addon"
  value       = aws_eks_addon.this.arn
}

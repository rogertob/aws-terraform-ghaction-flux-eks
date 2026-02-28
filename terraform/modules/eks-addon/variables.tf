variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "addon_name" {
  description = "EKS managed addon name"
  type        = string
}

variable "addon_version" {
  description = "Addon version. Null uses the latest recommended version for the cluster's Kubernetes version."
  type        = string
  default     = null
}

variable "configuration_values" {
  description = "Optional JSON string of configuration values passed to the addon. Schema varies per addon."
  type        = string
  default     = null
}

variable "service_account_role_arn" {
  description = "IAM role ARN for the addon's service account (IRSA). Not needed when using Pod Identity."
  type        = string
  default     = null
}

variable "pod_identity_associations" {
  description = "List of Pod Identity associations to configure on the addon. Each entry maps a service account to an IAM role."
  type = list(object({
    service_account = string
    role_arn        = string
  }))
  default = []
}

variable "resolve_conflicts_on_create" {
  description = "How to handle field conflicts on addon install."
  type        = string
  default     = "OVERWRITE"

  validation {
    condition     = contains(["NONE", "OVERWRITE"], var.resolve_conflicts_on_create)
    error_message = "Must be NONE or OVERWRITE."
  }
}

variable "resolve_conflicts_on_update" {
  description = "How to handle field conflicts on addon update. OVERWRITE keeps the addon authoritative."
  type        = string
  default     = "OVERWRITE"

  validation {
    condition     = contains(["NONE", "OVERWRITE", "PRESERVE"], var.resolve_conflicts_on_update)
    error_message = "Must be NONE, OVERWRITE, or PRESERVE."
  }
}

variable "tags" {
  description = "Tags to apply to the addon resource"
  type        = map(string)
  default     = {}
}

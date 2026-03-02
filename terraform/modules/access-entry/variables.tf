variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "principal_arn" {
  description = "IAM role or user ARN to grant access"
  type        = string
}

variable "policy_arn" {
  description = "EKS access policy ARN to associate"
  type        = string
}

variable "entry_type" {
  description = "Type of EKS access entry"
  type        = string
  # There is also hybrid but not using it 
  validation {
    condition     = contains(["STANDARD", "EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX"], var.entry_type)
    error_message = "Must be one of: STANDARD, EC2_LINUX, EC2_WINDOWS, FARGATE_LINUX."
  }
}

variable "access_scope_type" {
  description = "Scope of the access policy association (cluster or namespace)"
  type        = string

  validation {
    condition     = contains(["cluster", "namespace"], var.access_scope_type)
    error_message = "Must be either 'cluster' or 'namespace'."
  }
}

variable "namespaces" {
  description = "Kubernetes namespaces to scope access to. Required when access_scope_type is 'namespace'."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the access entry"
  type        = map(string)
  default     = {}
}

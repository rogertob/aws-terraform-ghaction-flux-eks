variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API server"
  type        = bool
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API server from within the VPC"
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = optional(number, 20)
    max_pods       = optional(number, null)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
}

variable "cluster_log_types" {
  description = "EKS control plane log types to enable"
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

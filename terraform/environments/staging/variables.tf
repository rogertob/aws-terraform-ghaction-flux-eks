variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "eks-poc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "github_org" {
  description = "GitHub organization or username that owns the repository"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name without the org prefix"
  type        = string
}

variable "github_token" {
  description = "GitHub PAT with repo read/write access"
  type        = string
  sensitive   = true
}

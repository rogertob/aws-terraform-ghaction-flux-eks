variable "flux_target_path" {
  description = "Path within the repo where Flux will look for cluster manifests"
  type        = string
}

variable "flux_version" {
  description = "Flux version to bootstrap (empty = latest stable)"
  type        = string
  default     = ""
}

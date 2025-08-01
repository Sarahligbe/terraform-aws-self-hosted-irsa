variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "distribution" {
  description = "Kubernetes distribution"
  type        = string
}

variable "distribution_config" {
  description = "Distribution-specific configuration"
  type = object({
    keys_path         = string
    keys_secret_mount = string
    restart_required  = bool
  })
}

variable "issuer_url" {
  description = "OIDC issuer URL"
  type        = string
}

variable "private_key_pem" {
  description = "Private key in PEM format"
  type        = string
  sensitive   = true
}

variable "public_key_pem" {
  description = "Public key in PEM format"
  type        = string
  sensitive   = true
}
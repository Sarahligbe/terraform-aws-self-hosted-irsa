variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "distribution" {
  description = "Kubernetes distribution"
  type        = string
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

variable "namespace" {
  description = "Namespace where aws pod identity webhook is installed"
  type        = string
  default     = "default"
}

variable "key_host_path" {
  description = "Local path to store IRSA keys"
  type        = string
}

variable "key_mount_path" {
  description = "Path to mount IRSA keys on the cluster"
  type        = string
}
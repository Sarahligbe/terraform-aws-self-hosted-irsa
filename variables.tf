variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "kubernetes_distribution" {
  description = "Kubernetes distribution"
  type        = string
  default     = "kubeadm"
  
  validation {
    condition = contains([
      "kubeadm", "k3s", "rke2", "kind", "minikube"
    ], var.kubernetes_distribution)
    error_message = "Supported distributions: kubeadm, k3s, rke2, kind, minikube"
  }
}

variable "execution_mode" {
  description = "Execution mode for JWKS generation"
  type        = string
  default     = "production"
}

variable "apply_kubernetes_manifests" {
  description = "Apply Kubernetes manifests to set up IRSA automatically"
  type        = bool
  default     = true
}

variable "kubernetes_connection" {
  description = "Kubernetes connection details (required only if apply_kubernetes_manifests = true)"
  type = object({
    config_path = optional(string)
    
    config_content = optional(string)
    
    host                   = optional(string)
    token                  = optional(string)
    cluster_ca_certificate = optional(string)
    client_certificate     = optional(string)
    client_key            = optional(string)
    
    use_current_context = optional(bool, true)
  })
  default = null
  
  validation {
    condition = !var.apply_kubernetes_manifests || var.kubernetes_connection != null
    error_message = "kubernetes_connection is required when apply_kubernetes_manifests is true."
  }
  
  validation {
    condition = var.kubernetes_connection == null || !var.apply_kubernetes_manifests || (
      var.kubernetes_connection.config_path != null ||
      var.kubernetes_connection.config_content != null ||
      var.kubernetes_connection.host != null ||
      var.kubernetes_connection.use_current_context == true
    )
    error_message = "When applying manifests, you must provide one of: config_path, config_content, host+token, or use_current_context=true."
  }
}

variable "irsa_keys_local_path" {
  description = "Local path to store IRSA keys"
  type        = string
  default     = null
}

variable "pod_identity_namespace" {
  description = "Namespace where aws pod identity webhook is installed"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}

variable "execution_mode" {
  description = "Execution mode for JWKS generation"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "production"], var.execution_mode)
    error_message = "execution_mode must be either 'development' or 'production'"
  }
}

variable "ssm_parameter_prefix" {
  description = "SSM parameter prefix for storing IRSA keys"
  type        = string
  default     = "/k8s/irsa"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "prefix" {
  description = "Prefix used for resource naming and tagging"
  type = string
  default = "self-managed"
}
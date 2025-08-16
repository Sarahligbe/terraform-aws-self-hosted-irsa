variable "execution_mode" {
  description = "Execution mode for JWKS generation"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "production"], var.execution_mode)
    error_message = "execution_mode must be either 'development' or 'production'"
  }
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

variable "namespace" {
  description = "Namespace where aws pod identity webhook is installed"
  type        = string
  default     = "default"
}

variable "jwks_lambda_role_arn" {
  description = "ARN for Lambda role to generate jwks" # get a better description
  type        = string
}
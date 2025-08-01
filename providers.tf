# providers.tf (in root module)
terraform {  
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.7.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubectl" {
  count = var.apply_kubernetes_manifests ? 1 : 0
  
  config_path    = var.kubernetes_connection != null ? var.kubernetes_connection.config_path : null
  host           = var.kubernetes_connection != null ? var.kubernetes_connection.host : null
  token          = var.kubernetes_connection != null ? var.kubernetes_connection.token : null
  cluster_ca_certificate = var.kubernetes_connection != null && var.kubernetes_connection.cluster_ca_certificate != null ? base64decode(var.kubernetes_connection.cluster_ca_certificate) : null
}
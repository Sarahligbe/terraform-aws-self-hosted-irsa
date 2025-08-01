locals {
  distribution_config = {
    kubeadm = {
      keys_path      = "/etc/kubernetes/irsa"
      keys_secret_mount = "/etc/kubernetes/irsa"
      restart_required = true
    }
    k3s = {
      keys_path      = "/var/lib/rancher/k3s/server/tls/service-account"
      keys_secret_mount = "/var/lib/rancher/k3s/server/tls/service-account"
      restart_required = true
    }
    rke2 = {
      keys_path      = "/var/lib/rancher/rke2/server/tls/service-account"
      keys_secret_mount = "/var/lib/rancher/rke2/server/tls/service-account"
      restart_required = true
    }
    kind = {
      keys_path      = "/etc/kubernetes/irsa"
      keys_secret_mount = "/etc/kubernetes/irsa"
      restart_required = false
    }
    minikube = {
      keys_path      = "/etc/kubernetes/irsa"
      keys_secret_mount = "/etc/kubernetes/irsa"
      restart_required = false
    }
  }
  
  current_dist_config = local.distribution_config[var.kubernetes_distribution]
  
  common_tags = merge(var.tags, {
    ManagedBy    = "terraform-irsa-module"
    Cluster      = var.cluster_name
    Distribution = var.kubernetes_distribution
  })
}

module "key_management" {
  source          = "./modules/key-management"
  
  prefix          = var.cluster_name
  execution_mode  = var.execution_mode
  region          = var.region
}

module "aws" {
  source                = "./modules/aws"
  
  prefix                = var.cluster_name
  region                = var.region
  discovery_bucket_name = module.key_management.discovery_bucket_name
  
  tags                  = local.common_tags
}

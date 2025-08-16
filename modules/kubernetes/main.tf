locals {
  irsa_keys = {
    "oidc-issuer.key" = {
      content    = var.private_key_pem
      permission = "0600"
      sensitive  = true
    }
    "oidc-issuer.pub" = {
      content    = var.public_key_pem
      permission = "0644"
      sensitive  = false
    }
  }
}

data "kubectl_file_documents" "pod_identity" {
    content = templatefile("aws-pod-identity-webhook.yaml",
    namespace       = "${var.namespace}",
    webhook_cert    = "${webhook_cert}",
    private_key_pem = "${webhook_key}"
    )
}

resource "kubectl_manifest" "pod_identity" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}

resource "local_sensitive_file" "irsa_keys" {
  for_each = local.irsa_keys
  
  content              = each.value.content
  filename             = "${var.key_host_path}/${each.key}"
  file_permission      = each.value.permission
  directory_permission = "0700"
}

data "kubectl_file_documents" "kubeadm" {
    count = var.distribution == "kubeadm" ? 1 : 0

    content = templatefile("kubeadm-config.yaml",
    issuer_url = "${var.issuer_url}",
    key_host_path  = "${var.key_host_path}",
    key_mount_path  = "${var.key_mount_path}",
    )
}

resource "kubectl_manifest" "kubeadm" {
    for_each  = var.distribution == kubeadm ? data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}
data "kubectl_file_documents" "k8s_sonfig" {
    content = templatefile("multi-doc-manifest.yaml")
}

resource "kubectl_manifest" "test" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}
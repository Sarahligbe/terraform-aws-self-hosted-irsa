ephemeral resource "tls_private_key" "oidc" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
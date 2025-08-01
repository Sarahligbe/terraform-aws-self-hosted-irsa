output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.main.url
}

output "oidc_provider" {
  value = "s3-${var.region}.amazonaws.com/${aws_s3_bucket.discovery_bucket.id}"
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.main.arn
}

output "service_account_issuer" {
  value = "https://s3-${var.region}.amazonaws.com/${aws_s3_bucket.discovery_bucket.id}"
}

output "discovery_bucket_arn" {
  value = "aws_s3_bucket.discovery_bucket.arn"
}

output "irsa_private_key_arn" {
  description = "ARN for the irsa private key"
  value = aws_ssm_parameter.private_key.arn
}

output "irsa_public_key_arn" {
  description = "ARN for the irsa public key"
  value = aws_ssm_parameter.public_key.arn
}

output "private_key_pem" {
  description = "IRSA private key"
  value = tls_private_key.irsa_signing_key.private_key_pem
}

output "public_key_pem" {
  description = "IRSA public key in PEM format"
  value = tls_private_key.irsa_signing_key.public_key_pem
}

output "discovery_bucket_name" {
  description = "S3 bucket name where the IRSA signing keys are stored"
  value = aws_s3_bucket.discovery_bucket.id
}
ephemeral resource "tls_private_key" "irsa_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

locals {
  is_development = var.execution_mode == "development"
  is_production  = var.execution_mode == "production"
  s3_jwks_key          = "keys.json"
}

resource "aws_s3_bucket" "discovery_bucket" {
  bucket = "${var.prefix}-aws-irsa-oidc-discovery"
}

resource "aws_s3_bucket_public_access_block" "discovery_bucket" {
  bucket = aws_s3_bucket.discovery_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "readonly_policy" {
  bucket = aws_s3_bucket.discovery_bucket.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = [
          aws_s3_bucket.discovery_bucket.arn,
          "${aws_s3_bucket.discovery_bucket.arn}/*",
        ]
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.discovery_bucket]
}

data "archive_file" "jwks_file" {
  count = local.is_production ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/generate-jwks.py"
  output_path = "${path.module}/generate-jwks.zip"
}

resource "aws_lambda_function" "jwks_generator" {
  filename         = data.archive_file.jwks_file.output_path
  function_name    = "${var.prefix}-jwks-generator"
  role             = var.jwks_lambda_role_arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.jwks_file.output_base64sha256

  runtime = "python3.12"

  tags = {
    Environment = "production"
  }
}

resource "aws_lambda_invocation" "generate_jwks" {
  count = local.is_production ? 1 : 0
  function_name = aws_lambda_function.jwks_generator.function_name
  
  input = jsonencode({
    public_key_pem        = tls_private_key.irsa_signing_key.public_key_pem
    discovery_bucket_name = aws_s3_bucket.discovery_bucket.id
    prefix                = var.prefix
    region                = var.region
  })
}

resource "aws_s3_object" "discovery_json" {
  bucket = aws_s3_bucket.discovery_bucket.id
  key    = ".well-known/openid-configuration"
  content = templatefile("${path.module}/discovery.json", {
    issuer_hostpath = "s3-${var.region}.amazonaws.com/${aws_s3_bucket.discovery_bucket.id}"
  })
  content_type = "application/json"
}

data "tls_certificate" "s3" {
  url = "https://s3-${var.region}.amazonaws.com"
}

resource "aws_iam_openid_connect_provider" "main" {
  url             = "https://s3-${var.region}.amazonaws.com/${aws_s3_bucket.discovery_bucket.id}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.s3.certificates[0].sha1_fingerprint]
}

ephemeral resource "tls_private_key" "webhook_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "webhook_cert" {
  private_key_pem = tls_private_key.webhook_key.private_key_pem
  
  subject {
    common_name = "pod-identity-webhook.${var.namespace}.svc"
  }
  
  dns_names = [
    "pod-identity-webhook"
    "pod-identity-webhook.${var.namespace}"
    "pod-identity-webhook.${var.namespace}.svc"
    "pod-identity-webhook.${var.namespace}.svc.local"
  ]
  
  validity_period_hours = 8760
  
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}
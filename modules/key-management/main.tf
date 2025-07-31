ephemeral resource "tls_private_key" "irsa_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

locals {
  is_development = var.execution_mode == "development"
  is_production  = var.execution_mode == "production"
  
  ssm_private_key_path = "${var.ssm_parameter_prefix}/private-key"
  ssm_public_key_path  = "${var.ssm_parameter_prefix}/public-key"
  s3_jwks_key        = "keys.json"
}

data "aws_iam_policy_document" "jwks_lambda_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "jwks_lambda_role" {
  count = local.is_production ? 1 : 0
  name  = "${var.cluster_name}-jwks-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.jwks_lambda_role.json
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
    ]
    effect = "Allow"

    resources = ["arn:aws:s3:::${var.s3_discovery_bucket_name}/*"]
  }
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "LAMBDAS3POLICY"
  description = "Provides permissions necessary for the lambda function to place objects in the s3 bucket"

  policy = data.aws_iam_policy_document.lambda_s3.json
}

resource "aws_iam_role_policy_attachment" "enable_s3" {
  role       = aws_iam_role.jwks_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
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
  role             = aws_iam_role.jwks_lambda_role.arn
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
    discovery_bucket_name = var.s3_discovery_bucket_name
    prefix          = var.prefix
    region                = var.region
  })
}

resource "aws_s3_object" "discovery_json" {
  bucket = var.s3_discovery_bucket_name
  key    = ".well-known/openid-configuration"
  content = templatefile("${path.module}/discovery.json", {
    issuer_hostpath = "s3-${var.region}.amazonaws.com/${var.s3_discovery_bucket_name}"
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
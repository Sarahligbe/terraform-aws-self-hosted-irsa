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
  name  = "${var.prefix}-jwks-lambda-role"
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

    resources = ["arn:aws:s3:::${var.discovery_bucket_name}/*"]
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
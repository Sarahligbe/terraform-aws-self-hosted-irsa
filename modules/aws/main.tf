data "aws_iam_policy_document" "ssm" {
  statement {
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:DeleteParameter",
    ]
    effect = "Allow"

    resources = ["*"]
  }
}

resource "aws_iam_policy" "k8s_ssm_policy" {
  name        = "control_plane_ssm"
  description = "Provides permission to put and get parameters in the ssm parameter store"

  policy = data.aws_iam_policy_document.ssm.json
}

resource "aws_iam_role" "k8s_ssm_role" {
  name = "control_plane_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm_attach" {
  name       = "control_plane_ssm_attach"
  roles      = [aws_iam_role.k8s_ssm_role.name]
  policy_arn = aws_iam_policy.k8s_ssm_policy.arn
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "control_plane_ssm_profile"
  role = aws_iam_role.k8s_ssm_role.name
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
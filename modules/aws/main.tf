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
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.discovery_bucket.arn,
          "${aws_s3_bucket.discovery_bucket.arn}/*",
        ]
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.discovery_bucket]
}
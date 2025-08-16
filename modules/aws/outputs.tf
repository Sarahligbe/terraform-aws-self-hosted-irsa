output "jwks_lambda_role_arn" {
  description = "ARN for Lambda role to generate jwks" # get a better description
  value = aws_iam_role.jwks_lambda_role.arn
}
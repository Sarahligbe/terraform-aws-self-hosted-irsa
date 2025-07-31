output "ssm_role_name" {
  description = "SSM role name"
  value = aws_iam_role.k8s_ssm_role.name
}

output "ssm_profile_name" {
  description = "SSM profile name"
  value = aws_iam_instance_profile.ssm_profile.name
}
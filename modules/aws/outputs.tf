output "cp_ssm_role_name" {
  description = "Control plane ssm role name"
  value = aws_iam_role.k8s_ssm_role.name
}

output "cp_ssm_profile_name" {
  description = "Control plane ssm role name"
  value = aws_iam_instance_profile.ssm_profile.name
}

output "s3_discovery_bucket_name" {
  value = aws_s3_bucket.discovery_bucket.id
}
variable "prefix" {
  description = "Prefix used for resource naming and tagging"
  type = string
  default = "self-managed"
}

variable "discovery_bucket_name" {
  description = "S3 discovery bucket name"
  type = string
}
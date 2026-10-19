variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "environment" {
  description = "Environment tag for the bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Whether bucket versioning is enabled"
  type        = bool
}

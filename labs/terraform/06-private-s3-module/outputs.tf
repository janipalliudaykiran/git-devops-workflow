output "s3_bucket_name" {
  description = "Name of the provisioned S3 bucket"
  value       = module.private_bucket.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the provisioned S3 bucket"
  value       = module.private_bucket.bucket_arn
}

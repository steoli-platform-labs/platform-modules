# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
output "bucket_names" {
  description = "Bucket names created"
  value       = { for k, b in aws_s3_bucket.this : k => b.bucket }
}

output "bucket_arns" {
  description = "Bucket ARNs created"
  value       = { for k, b in aws_s3_bucket.this : k => b.arn }
}

output "bucket_ids" {
  description = "Bucket IDs (same as names for S3)"
  value       = { for k, b in aws_s3_bucket.this : k => b.id }
}

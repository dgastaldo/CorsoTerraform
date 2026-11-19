output "bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "bucket_domain" {
  value = aws_s3_bucket.main.bucket_regional_domain_name
}

output "app_secret" {
  value     = random_password.app.result
  sensitive = true
}

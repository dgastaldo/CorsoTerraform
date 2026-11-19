terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

provider "aws" {
}

variable "student" {
  type = string
}

resource "aws_s3_bucket" "main" {
  bucket = "broken-${var.student}"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.mian.id

  versioning_configuration {
    status = "Enabeld"
  }
}

resource "aws_sns_topic" "extra" {
  count = "due"
  name  = "broken-extra-${count.index}"
}

output "bucket_domain" {
  value = aws_s3_bucket.main.bucket_regional_domain_nam
}

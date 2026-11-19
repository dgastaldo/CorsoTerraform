locals {
  tags = {
    course      = "dvo05"
    owner       = var.student
    environment = var.environment
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket" "main" {
  # 3-63 caratteri, solo minuscole, numeri e trattini, univoco a livello globale
  bucket        = "tfcourse-${var.student}-${var.environment}-${random_string.suffix.result}"
  force_destroy = true # il bucket di prova si cancella anche se contiene oggetti
  tags          = local.tags
}

# Su AWS le impostazioni del bucket sono risorse separate (dal provider 4.x in poi)
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Un segreto generato: finisce in chiaro nello state, anche se l'output e sensitive
resource "random_password" "app" {
  length  = 24
  special = true
}

# Test eseguiti con provider simulato: nessuna risorsa reale viene creata.
mock_provider "aws" {}

variables {
  student = "demo"
}

run "accesso_pubblico_bloccato" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.main.block_public_acls,
      aws_s3_bucket_public_access_block.main.block_public_policy,
      aws_s3_bucket_public_access_block.main.ignore_public_acls,
      aws_s3_bucket_public_access_block.main.restrict_public_buckets,
    ])
    error_message = "Il bucket deve bloccare ogni forma di accesso pubblico."
  }
}

run "nome_bucket_valido" {
  command = apply

  assert {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", aws_s3_bucket.main.bucket))
    error_message = "Il nome del bucket non rispetta i vincoli di S3."
  }
}

run "student_non_valido_rifiutato" {
  command = plan

  variables {
    student = "NOME_NON_VALIDO"
  }

  expect_failures = [var.student]
}

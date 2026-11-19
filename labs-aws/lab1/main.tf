terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Regione AWS (anche via TF_VAR_region)"
}

variable "student" {
  type        = string
  description = "Sigla personale, es. mrossi"
}

# Un topic SNS: gratuito, si crea in un secondo, ha un nome che forza la sostituzione
resource "aws_sns_topic" "main" {
  name = "tfcourse-${var.student}"

  tags = {
    course  = "dvo05"
    student = var.student
    test    = "test"
  }
}

output "topic_arn" {
  value = aws_sns_topic.main.arn
}

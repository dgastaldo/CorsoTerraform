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
  type    = string
  default = "eu-west-1"
}

variable "student" {
  type = string
}

# 1) Il log group è stato creato a mano con aws CLI (vedi guida).
# 2) Si dichiara l'import; la configurazione la genera Terraform:
#    terraform plan -generate-config-out=generated.tf
import {
  to = aws_cloudwatch_log_group.legacy
  id = "/tfcourse/legacy-${var.student}"
}

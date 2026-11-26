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

variable "environments" {
  type = map(object({
    vpc_cidr = string
    subnets  = map(object({ cidr = string }))
  }))
  default = {
    dev = {
      vpc_cidr = "10.10.0.0/16"
      subnets = {
        web = { cidr = "10.10.1.0/24" }
        db  = { cidr = "10.10.2.0/24" }
      }
    }
    prod = {
      vpc_cidr = "10.20.0.0/16"
      subnets = {
        web  = { cidr = "10.20.1.0/24" }
        db   = { cidr = "10.20.2.0/24" }
        mgmt = { cidr = "10.20.3.0/24" }
      }
    }
  }
}

module "network" {
  source   = "./modules/network"
  for_each = var.environments

  name_prefix = "${var.student}-${each.key}"
  vpc_cidr    = each.value.vpc_cidr
  subnets     = each.value.subnets
  tags        = { course = "dvo05", environment = each.key }
}

output "vpc_ids" {
  value = { for env, m in module.network : env => m.vpc_id }
}

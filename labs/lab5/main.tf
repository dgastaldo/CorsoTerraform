terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14"
    }
  }
}

provider "azurerm" {
  features {}
  # azurerm prova a registrare i resource provider "core" all'avvio: senza il
  # permesso di registrazione sulla subscription il plan fallisce con un 403.
  # Con "none" non ci prova; Microsoft.Network, Compute e Storage devono essere
  # gia registrati (verifica-prerequisiti lo controlla).
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
}

variable "subscription_id" {
  type = string
}

variable "student" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "environments" {
  type = map(object({
    address_space = list(string)
    subnets       = map(object({ cidr = string }))
  }))
  default = {
    dev = {
      address_space = ["10.10.0.0/16"]
      subnets = {
        web = { cidr = "10.10.1.0/24" }
        db  = { cidr = "10.10.2.0/24" }
      }
    }
    prod = {
      address_space = ["10.20.0.0/16"]
      subnets = {
        web  = { cidr = "10.20.1.0/24" }
        db   = { cidr = "10.20.2.0/24" }
        mgmt = { cidr = "10.20.3.0/24" }
      }
    }
    cert = {
      address_space = ["10.30.0.0/16"]
      subnets = {
        web = { cidr = "10.30.1.0/24" }
        db  = { cidr = "10.30.2.0/24" }
      }
    }
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-tfcourse-mod-${var.student}"
  location = var.location
}

module "network" {
  source   = "./modules/network"
  for_each = var.environments

  name_prefix         = "${var.student}-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = each.value.address_space
  subnets             = each.value.subnets
  tags                = { environment = each.key }
}

output "vnet_ids" {
  value = { for env, m in module.network : env => m.vnet_id }
}

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
  type        = string
  description = "ID della subscription Azure (anche via TF_VAR_subscription_id)"
}

variable "student" {
  type        = string
  description = "Sigla personale, es. mrossi"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-tfcourse-${var.student}"
  location = "italynorth"

  tags = {
    course  = "dvo05"
    student = var.student
    test    = "test"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.main.id
}

terraform {
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
}

variable "student" {
  type = string
}

resource "azurerm_resource_group" "main" {
  name = "rg-broken-${var.student}"
}

resource "azurerm_storage_account" "main" {
  name                     = "stbroken${var.student}"
  resource_group_name      = azurerm_resource_group.mian.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS_1_2"
}

resource "azurerm_resource_group" "extra" {
  count    = "due"
  name     = "rg-broken-extra-${count.index}"
  location = "westeurope"
}

output "blob_endpoint" {
  value = azurerm_storage_account.main.primary_blob_enpoint
}

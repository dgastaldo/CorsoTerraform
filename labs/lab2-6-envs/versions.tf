terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
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
  resource_providers_to_register  = ["Microsoft.Storage"]
  subscription_id                 = var.subscription_id
}

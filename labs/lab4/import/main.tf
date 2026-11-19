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
  resource_providers_to_register = [
    "Microsoft.Network",
    "Microsoft.Storage",
  ]
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type    = string
  default = "2182d27a-0f9d-4967-ade7-463142662428"
}

variable "student" {
  type    = string
  default = "dgast"
}

# 1) Il resource group è stato creato a mano con az CLI (vedi guida).
# 2) Si dichiara l'import; la configurazione la genera Terraform:
#    terraform plan -generate-config-out=generated.tf
moved {
  from = azurerm_resource_group.legacy
  to   = azurerm_resource_group.new
}

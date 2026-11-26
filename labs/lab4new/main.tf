data "azurerm_client_config" "current" {}

locals {
  prefix = "tfcourse-${var.student}"
  tags = {
    course = "dvo05"
    owner  = var.student
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.address_space
  tags                = local.tags
}

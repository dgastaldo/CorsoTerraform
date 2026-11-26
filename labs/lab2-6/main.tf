locals {
  tags = {
    course      = "dvo05"
    owner       = var.student
    environment = var.environment
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-tfcourse-dg-${var.environment}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "main" {
  # max 24 caratteri, solo minuscole e numeri, univoco a livello globale
  name                     = "staccdg${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false # nessun blob pubblico
  tags                            = local.tags
  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
    ignore_changes        = [tags["owner"]]
  }
}

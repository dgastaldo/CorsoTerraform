# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform
resource "azurerm_storage_account" "legacy" {
  access_tier                       = "Hot"
  account_kind                      = "StorageV2"
  account_replication_type          = "LRS"
  account_tier                      = "Standard"
  allow_nested_items_to_be_public   = false
  allowed_copy_scope                = null
  cross_tenant_replication_enabled  = false
  default_to_oauth_authentication   = false
  dns_endpoint_type                 = "Standard"
  edge_zone                         = null
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = false
  is_hns_enabled                    = false
  large_file_share_enabled          = false
  local_user_enabled                = true
  location                          = "westeurope"
  min_tls_version                   = "TLS1_2"
  name                              = "testimportdgast"
  nfsv3_enabled                     = false
  provisioned_billing_model_version = null
  public_network_access             = "Enabled"
  queue_encryption_key_type         = "Service"
  resource_group_name               = "rg-tfcourse-dgast"
  sftp_enabled                      = false
  shared_access_key_enabled         = true
  smb_oauth_enabled                 = false
  table_encryption_key_type         = "Service"
  tags                              = {}
  blob_properties {
    change_feed_enabled           = false
    change_feed_retention_in_days = 0
    last_access_time_enabled      = false
    versioning_enabled            = false
    container_delete_retention_policy {
      days = 7
    }
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }
  share_properties {
    retention_policy {
      days = 7
    }
  }
}

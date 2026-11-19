# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "/subscriptions/2182d27a-0f9d-4967-ade7-463142662428/resourceGroups/rg-tfcourse-dgast"
resource "azurerm_resource_group" "legacy" {
  location   = "westeurope"
  managed_by = null
  name       = "rg-tfcourse-dgast"
  tags = {
    course = "dvo05"
    owner  = "dgast"
  }
}

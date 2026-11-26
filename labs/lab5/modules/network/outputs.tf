output "vnet_id" {
  value = {
    net_id     = azurerm_virtual_network.this.id
    subnet_ids = { for k, s in azurerm_subnet.this : k => s.id }
  }
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}

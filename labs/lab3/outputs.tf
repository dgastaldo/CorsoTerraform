output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}

output "web_url" {
  value = "http://${azurerm_public_ip.web.ip_address}"
}

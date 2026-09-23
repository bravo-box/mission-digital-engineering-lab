output "id" {
  description = "Resource ID of API Management."
  value       = azurerm_api_management.gateway.id
}

output "name" {
  description = "Name of API Management."
  value       = azurerm_api_management.gateway.name
}

output "gateway_url" {
  description = "Private gateway URL of API Management."
  value       = azurerm_api_management.gateway.gateway_url
}

output "developer_portal_url" {
  description = "Developer portal URL used to discover and subscribe to the Foundry API."
  value       = azurerm_api_management.gateway.developer_portal_url
}

output "principal_id" {
  description = "Principal ID of the API Management system-assigned identity."
  value       = azurerm_api_management.gateway.identity[0].principal_id
}

output "id" {
  description = "Resource ID of the Foundry account."
  value       = azurerm_cognitive_account.foundry.id
}

output "name" {
  description = "Name of the Foundry account."
  value       = azurerm_cognitive_account.foundry.name
}

output "endpoint" {
  description = "Endpoint of the Foundry account."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "id" {
  description = "Resource ID of the key vault."
  value       = azurerm_key_vault.lab.id
}

output "name" {
  description = "Name of the key vault."
  value       = azurerm_key_vault.lab.name
}

output "vault_uri" {
  description = "URI of the key vault."
  value       = azurerm_key_vault.lab.vault_uri
}

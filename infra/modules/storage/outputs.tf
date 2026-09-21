output "id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.data.id
}

output "name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.data.name
}

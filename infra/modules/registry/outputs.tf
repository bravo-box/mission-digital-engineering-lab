output "id" {
  description = "Resource ID of the container registry."
  value       = azurerm_container_registry.lab.id
}

output "name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.lab.name
}

output "login_server" {
  description = "Login server of the container registry."
  value       = azurerm_container_registry.lab.login_server
}

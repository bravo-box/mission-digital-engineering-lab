output "virtual_network_id" {
  description = "Resource ID of the existing virtual network."
  value       = data.azurerm_virtual_network.lab.id
}

output "subnet_ids_by_purpose" {
  description = "Subnet resource IDs keyed by their logical purpose."
  value       = { for key, subnet in azurerm_subnet.lab : key => subnet.id }
}

output "subnet_ids" {
  description = "Subnet resource IDs keyed by subnet name."
  value       = { for key, subnet in azurerm_subnet.lab : local.subnet_names[key] => subnet.id }
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion host, when deployed."
  value       = var.deploy_bastion ? azurerm_bastion_host.lab[0].name : null
}

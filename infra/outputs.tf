output "resource_group_name" {
  description = "Resource group holding the lab resources."
  value       = azurerm_resource_group.lab.name
}

output "subnet_ids" {
  description = "Resource IDs of the lab subnets, keyed by purpose."
  value       = { for key, subnet in azurerm_subnet.lab : local.subnet_names[key] => subnet.id }
}

output "aks_cluster_name" {
  description = "Name of the private AKS cluster running MATLAB Parallel Server."
  value       = azurerm_kubernetes_cluster.lab.name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL used for workload identity federation."
  value       = azurerm_kubernetes_cluster.lab.oidc_issuer_url
}

output "container_registry_name" {
  description = "Name of the private container registry."
  value       = azurerm_container_registry.lab.name
}

output "container_registry_login_server" {
  description = "Login server of the private container registry."
  value       = azurerm_container_registry.lab.login_server
}

output "storage_account_name" {
  description = "Name of the data storage account (key based access disabled)."
  value       = azurerm_storage_account.data.name
}

output "key_vault_name" {
  description = "Name of the lab key vault."
  value       = azurerm_key_vault.lab.name
}

output "key_vault_uri" {
  description = "URI of the lab key vault."
  value       = azurerm_key_vault.lab.vault_uri
}

output "foundry_account_name" {
  description = "Name of the Azure AI Foundry (AI Services) account."
  value       = azurerm_cognitive_account.foundry.name
}

output "foundry_endpoint" {
  description = "Private endpoint aware endpoint of the AI Foundry account."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion host, when deployed."
  value       = var.deploy_bastion ? azurerm_bastion_host.lab[0].name : null
}

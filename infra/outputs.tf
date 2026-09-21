output "resource_group_name" {
  description = "Resource group holding the lab resources."
  value       = azurerm_resource_group.lab.name
}

output "subnet_ids" {
  description = "Resource IDs of the lab subnets, keyed by purpose."
  value       = module.network.subnet_ids
}

output "aks_cluster_name" {
  description = "Name of the private AKS cluster running MATLAB Parallel Server."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL used for workload identity federation."
  value       = module.aks.oidc_issuer_url
}

output "container_registry_name" {
  description = "Name of the private container registry."
  value       = module.registry.name
}

output "container_registry_login_server" {
  description = "Login server of the private container registry."
  value       = module.registry.login_server
}

output "storage_account_name" {
  description = "Name of the data storage account (key based access disabled)."
  value       = module.storage.name
}

output "key_vault_name" {
  description = "Name of the lab key vault."
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "URI of the lab key vault."
  value       = module.key_vault.vault_uri
}

output "foundry_account_name" {
  description = "Name of the Azure AI Foundry (AI Services) account."
  value       = module.foundry.name
}

output "foundry_endpoint" {
  description = "Private endpoint aware endpoint of the AI Foundry account."
  value       = module.foundry.endpoint
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion host, when deployed."
  value       = module.network.bastion_host_name
}

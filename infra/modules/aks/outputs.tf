output "id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.lab.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.lab.name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used for workload identity federation."
  value       = azurerm_kubernetes_cluster.lab.oidc_issuer_url
}

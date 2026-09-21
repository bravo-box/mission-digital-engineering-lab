moved {
  from = azurerm_subnet.lab
  to   = module.network.azurerm_subnet.lab
}

moved {
  from = azurerm_network_security_group.lab
  to   = module.network.azurerm_network_security_group.lab
}

moved {
  from = azurerm_subnet_network_security_group_association.lab
  to   = module.network.azurerm_subnet_network_security_group_association.lab
}

moved {
  from = azurerm_subnet.bastion
  to   = module.network.azurerm_subnet.bastion
}

moved {
  from = azurerm_public_ip.bastion
  to   = module.network.azurerm_public_ip.bastion
}

moved {
  from = azurerm_bastion_host.lab
  to   = module.network.azurerm_bastion_host.lab
}

moved {
  from = azurerm_storage_account.data
  to   = module.storage.azurerm_storage_account.data
}

moved {
  from = module.pe_storage_blob
  to   = module.storage.module.private_endpoint_blob
}

moved {
  from = module.pe_storage_dfs
  to   = module.storage.module.private_endpoint_dfs
}

moved {
  from = azurerm_container_registry.lab
  to   = module.registry.azurerm_container_registry.lab
}

moved {
  from = module.pe_registry
  to   = module.registry.module.private_endpoint
}

moved {
  from = azurerm_key_vault.lab
  to   = module.key_vault.azurerm_key_vault.lab
}

moved {
  from = azurerm_role_assignment.key_vault_admin
  to   = module.key_vault.azurerm_role_assignment.admin
}

moved {
  from = module.pe_key_vault
  to   = module.key_vault.module.private_endpoint
}

moved {
  from = azurerm_cognitive_account.foundry
  to   = module.foundry.azurerm_cognitive_account.foundry
}

moved {
  from = module.pe_foundry
  to   = module.foundry.module.private_endpoint
}

moved {
  from = azurerm_user_assigned_identity.aks
  to   = module.aks.azurerm_user_assigned_identity.aks
}

moved {
  from = azurerm_role_assignment.aks_network_contributor
  to   = module.aks.azurerm_role_assignment.network_contributor
}

moved {
  from = azurerm_kubernetes_cluster.lab
  to   = module.aks.azurerm_kubernetes_cluster.lab
}

moved {
  from = azurerm_kubernetes_cluster_node_pool.matlab
  to   = module.aks.azurerm_kubernetes_cluster_node_pool.matlab
}

moved {
  from = azurerm_role_assignment.aks_acr_pull
  to   = module.aks.azurerm_role_assignment.acr_pull
}

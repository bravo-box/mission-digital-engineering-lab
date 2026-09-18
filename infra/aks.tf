resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name_prefix}-aks"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.tags
}

# The cluster identity manages the subnet and the private DNS zone entries of
# the private cluster, so it needs Network Contributor on the lab subnets.
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.lab["matlab_cluster"].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Private AKS cluster hosting MATLAB Parallel Server workloads.
resource "azurerm_kubernetes_cluster" "lab" {
  name                = "aks-${var.name_prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  dns_prefix          = "aks-${var.name_prefix}"
  kubernetes_version  = var.aks_kubernetes_version
  node_resource_group = "rg-${var.name_prefix}-aks-nodes"
  tags                = local.tags

  private_cluster_enabled             = true
  private_dns_zone_id                 = "System"
  private_cluster_public_fqdn_enabled = false
  local_account_disabled              = var.aks_local_account_disabled
  oidc_issuer_enabled                 = true
  workload_identity_enabled           = true
  image_cleaner_enabled               = true

  default_node_pool {
    name                         = "system"
    node_count                   = var.aks_system_node_count
    vm_size                      = var.aks_system_node_size
    vnet_subnet_id               = azurerm_subnet.lab["matlab_cluster"].id
    only_critical_addons_enabled = true
    os_sku                       = "AzureLinux"
    max_pods                     = 100
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = var.aks_admin_group_object_ids
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = var.aks_outbound_type
    pod_cidr            = var.aks_pod_cidr
    service_cidr        = var.aks_service_cidr
    dns_service_ip      = var.aks_dns_service_ip
  }

  depends_on = [azurerm_role_assignment.aks_network_contributor]
}

# MATLAB parallel worker pool.
resource "azurerm_kubernetes_cluster_node_pool" "matlab" {
  name                  = "matlab"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.lab.id
  vm_size               = var.aks_matlab_node_size
  node_count            = var.aks_matlab_node_count
  vnet_subnet_id        = azurerm_subnet.lab["matlab_cluster"].id
  os_sku                = "AzureLinux"
  max_pods              = 100
  tags                  = local.tags

  node_labels = {
    "workload" = "matlab-parallel"
  }
}

# Allow the cluster to pull the MATLAB images from the private registry.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.lab.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.lab.kubelet_identity[0].object_id
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name_prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_kubernetes_cluster" "lab" {
  name                = "aks-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "aks-${var.name_prefix}"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "rg-${var.name_prefix}-aks-nodes"
  tags                = var.tags

  private_cluster_enabled             = true
  private_dns_zone_id                 = "System"
  private_cluster_public_fqdn_enabled = false
  local_account_disabled              = var.local_account_disabled
  oidc_issuer_enabled                 = true
  workload_identity_enabled           = true
  image_cleaner_enabled               = true

  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    vm_size                      = var.system_node_size
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true
    os_sku                       = "AzureLinux"
    max_pods                     = 100
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  depends_on = [azurerm_role_assignment.network_contributor]
}

resource "azurerm_kubernetes_cluster_node_pool" "matlab" {
  name                  = "matlab"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.lab.id
  vm_size               = var.matlab_node_size
  node_count            = var.matlab_node_count
  vnet_subnet_id        = var.subnet_id
  os_sku                = "AzureLinux"
  max_pods              = 100
  tags                  = var.tags

  node_labels = {
    "workload" = "matlab-parallel"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.lab.kubelet_identity[0].object_id
}

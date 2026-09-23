data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  resource_group_name = coalesce(var.resource_group_name, "rg-${var.name_prefix}-lab")
  suffix              = random_string.suffix.result

  tags = merge({
    workload    = "digital-engineering-lab"
    provisioner = "terraform"
  }, var.tags)

  # Private DNS zone names differ per cloud.
  private_dns_zone_names = {
    public = {
      blob           = "privatelink.blob.core.windows.net"
      dfs            = "privatelink.dfs.core.windows.net"
      vault          = "privatelink.vaultcore.azure.net"
      registry       = "privatelink.azurecr.io"
      cognitive      = "privatelink.cognitiveservices.azure.com"
      openai         = "privatelink.openai.azure.com"
      ai             = "privatelink.services.ai.azure.com"
      api_management = "azure-api.net"
    }
    usgovernment = {
      blob           = "privatelink.blob.core.usgovcloudapi.net"
      dfs            = "privatelink.dfs.core.usgovcloudapi.net"
      vault          = "privatelink.vaultcore.usgovcloudapi.net"
      registry       = "privatelink.azurecr.us"
      cognitive      = "privatelink.cognitiveservices.azure.us"
      openai         = "privatelink.openai.azure.us"
      ai             = "privatelink.services.ai.azure.us"
      api_management = "azure-api.us"
    }
    china = {
      blob           = "privatelink.blob.core.chinacloudapi.cn"
      dfs            = "privatelink.dfs.core.chinacloudapi.cn"
      vault          = "privatelink.vaultcore.azure.cn"
      registry       = "privatelink.azurecr.cn"
      cognitive      = "privatelink.cognitiveservices.azure.cn"
      openai         = "privatelink.openai.azure.cn"
      ai             = "privatelink.services.ai.azure.cn"
      api_management = "azure-api.cn"
    }
  }

  dns_zones = local.private_dns_zone_names[var.azure_environment]
}

resource "azurerm_resource_group" "lab" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Private DNS zones, linked to the existing virtual network so that every
# private endpoint resolves privately and no public egress is required.
# ---------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "lab" {
  for_each = local.dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "lab" {
  for_each = azurerm_private_dns_zone.lab

  name                  = "${var.name_prefix}-${each.key}-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = module.network.virtual_network_id
  registration_enabled  = false
  tags                  = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix                         = var.name_prefix
  location                            = azurerm_resource_group.lab.location
  resource_group_name                 = azurerm_resource_group.lab.name
  virtual_network_name                = var.virtual_network_name
  virtual_network_resource_group_name = var.virtual_network_resource_group_name
  subnet_address_prefixes             = var.subnet_address_prefixes
  deploy_bastion                      = var.deploy_bastion
  bastion_subnet_address_prefix       = var.bastion_subnet_address_prefix
  bastion_sku                         = var.bastion_sku
  tags                                = local.tags
}

module "storage" {
  source = "./modules/storage"

  name_prefix              = var.name_prefix
  suffix                   = local.suffix
  location                 = azurerm_resource_group.lab.location
  resource_group_name      = azurerm_resource_group.lab.name
  subnet_id                = module.network.subnet_ids_by_purpose["storage"]
  replication_type         = var.storage_account_replication_type
  blob_private_dns_zone_id = azurerm_private_dns_zone.lab["blob"].id
  dfs_private_dns_zone_id  = azurerm_private_dns_zone.lab["dfs"].id
  tags                     = local.tags
}

module "registry" {
  source = "./modules/registry"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = module.network.subnet_ids_by_purpose["registry"]
  private_dns_zone_id = azurerm_private_dns_zone.lab["registry"].id
  tags                = local.tags
}

module "key_vault" {
  source = "./modules/key_vault"

  name_prefix          = var.name_prefix
  suffix               = local.suffix
  location             = azurerm_resource_group.lab.location
  resource_group_name  = azurerm_resource_group.lab.name
  tenant_id            = data.azurerm_client_config.current.tenant_id
  current_principal_id = data.azurerm_client_config.current.object_id
  admin_object_ids     = var.key_vault_admin_object_ids
  subnet_id            = module.network.subnet_ids_by_purpose["key_vault"]
  private_dns_zone_id  = azurerm_private_dns_zone.lab["vault"].id
  tags                 = local.tags
}

module "foundry" {
  source = "./modules/foundry"

  name_prefix         = var.name_prefix
  suffix              = local.suffix
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = var.foundry_sku
  subnet_id           = module.network.subnet_ids_by_purpose["foundry"]
  private_dns_zone_ids = [
    azurerm_private_dns_zone.lab["cognitive"].id,
    azurerm_private_dns_zone.lab["openai"].id,
    azurerm_private_dns_zone.lab["ai"].id,
  ]
  tags = local.tags
}

module "api_management" {
  source = "./modules/api_management"

  name_prefix           = var.name_prefix
  suffix                = local.suffix
  location              = azurerm_resource_group.lab.location
  resource_group_name   = azurerm_resource_group.lab.name
  subnet_id             = module.network.subnet_ids_by_purpose["api_management"]
  sku_name              = var.api_management_sku
  publisher_name        = var.api_management_publisher_name
  publisher_email       = var.api_management_publisher_email
  foundry_account_id    = module.foundry.id
  foundry_endpoint      = module.foundry.endpoint
  private_dns_zone_name = azurerm_private_dns_zone.lab["api_management"].name
  managed_identity_audience = {
    public       = "https://cognitiveservices.azure.com"
    usgovernment = "https://cognitiveservices.azure.us"
    china        = "https://cognitiveservices.azure.cn"
  }[var.azure_environment]
  tags = local.tags

  depends_on = [
    module.network,
    module.foundry,
    azurerm_private_dns_zone_virtual_network_link.lab["api_management"],
  ]
}

module "aks" {
  source = "./modules/aks"

  name_prefix            = var.name_prefix
  suffix                 = local.suffix
  location               = azurerm_resource_group.lab.location
  resource_group_name    = azurerm_resource_group.lab.name
  tenant_id              = data.azurerm_client_config.current.tenant_id
  subnet_id              = module.network.subnet_ids_by_purpose["matlab_cluster"]
  container_registry_id  = module.registry.id
  kubernetes_version     = var.aks_kubernetes_version
  system_node_count      = var.aks_system_node_count
  system_node_size       = var.aks_system_node_size
  service_cidr           = var.aks_service_cidr
  dns_service_ip         = var.aks_dns_service_ip
  outbound_type          = var.aks_outbound_type
  pod_cidr               = var.aks_pod_cidr
  admin_group_object_ids = var.aks_admin_group_object_ids
  local_account_disabled = var.aks_local_account_disabled
  matlab_node_count      = var.aks_matlab_node_count
  matlab_node_size       = var.aks_matlab_node_size
  tags                   = local.tags
}

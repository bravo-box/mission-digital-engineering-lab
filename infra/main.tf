data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "lab" {
  name                = var.virtual_network_name
  resource_group_name = var.virtual_network_resource_group_name
}

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
      blob      = "privatelink.blob.core.windows.net"
      dfs       = "privatelink.dfs.core.windows.net"
      vault     = "privatelink.vaultcore.azure.net"
      registry  = "privatelink.azurecr.io"
      cognitive = "privatelink.cognitiveservices.azure.com"
      openai    = "privatelink.openai.azure.com"
      ai        = "privatelink.services.ai.azure.com"
    }
    usgovernment = {
      blob      = "privatelink.blob.core.usgovcloudapi.net"
      dfs       = "privatelink.dfs.core.usgovcloudapi.net"
      vault     = "privatelink.vaultcore.usgovcloudapi.net"
      registry  = "privatelink.azurecr.us"
      cognitive = "privatelink.cognitiveservices.azure.us"
      openai    = "privatelink.openai.azure.us"
      ai        = "privatelink.services.ai.azure.us"
    }
    china = {
      blob      = "privatelink.blob.core.chinacloudapi.cn"
      dfs       = "privatelink.dfs.core.chinacloudapi.cn"
      vault     = "privatelink.vaultcore.azure.cn"
      registry  = "privatelink.azurecr.cn"
      cognitive = "privatelink.cognitiveservices.azure.cn"
      openai    = "privatelink.openai.azure.cn"
      ai        = "privatelink.services.ai.azure.cn"
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
  virtual_network_id    = data.azurerm_virtual_network.lab.id
  registration_enabled  = false
  tags                  = local.tags
}

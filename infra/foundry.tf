# Azure AI Foundry (AI Services) account used for LLM access from the lab.
# Reachable only over private link, and local (key based) auth is disabled.
resource "azurerm_cognitive_account" "foundry" {
  name                = "ais-${var.name_prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  kind                = "AIServices"
  sku_name            = var.foundry_sku
  tags                = local.tags

  custom_subdomain_name              = "ais-${var.name_prefix}-${local.suffix}"
  local_auth_enabled                 = false
  public_network_access_enabled      = false
  outbound_network_access_restricted = true

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = "Deny"
  }
}

module "pe_foundry" {
  source = "./modules/private_endpoint"

  name                           = "pe-${var.name_prefix}-foundry"
  location                       = azurerm_resource_group.lab.location
  resource_group_name            = azurerm_resource_group.lab.name
  subnet_id                      = azurerm_subnet.lab["foundry"].id
  private_connection_resource_id = azurerm_cognitive_account.foundry.id
  subresource_names              = ["account"]
  tags                           = local.tags

  private_dns_zone_ids = [
    azurerm_private_dns_zone.lab["cognitive"].id,
    azurerm_private_dns_zone.lab["openai"].id,
    azurerm_private_dns_zone.lab["ai"].id,
  ]
}

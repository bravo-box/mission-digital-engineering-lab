# Premium registry so that private link and OCI artifact support (air-gap
# imports/exports) are available. Public network access is disabled.
resource "azurerm_container_registry" "lab" {
  name                = substr("cr${var.name_prefix}${local.suffix}", 0, 50)
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  sku                 = "Premium"
  tags                = local.tags

  admin_enabled                 = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = true
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  identity {
    type = "SystemAssigned"
  }

  retention_policy_in_days = 30
  trust_policy_enabled     = false
}

module "pe_registry" {
  source = "./modules/private_endpoint"

  name                           = "pe-${var.name_prefix}-registry"
  location                       = azurerm_resource_group.lab.location
  resource_group_name            = azurerm_resource_group.lab.name
  subnet_id                      = azurerm_subnet.lab["registry"].id
  private_connection_resource_id = azurerm_container_registry.lab.id
  subresource_names              = ["registry"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.lab["registry"].id]
  tags                           = local.tags
}

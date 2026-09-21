resource "azurerm_container_registry" "lab" {
  name                = substr("cr${var.name_prefix}${var.suffix}", 0, 50)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  tags                = var.tags

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

module "private_endpoint" {
  source = "../private_endpoint"

  name                           = "pe-${var.name_prefix}-registry"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_container_registry.lab.id
  subresource_names              = ["registry"]
  private_dns_zone_ids           = [var.private_dns_zone_id]
  tags                           = var.tags
}

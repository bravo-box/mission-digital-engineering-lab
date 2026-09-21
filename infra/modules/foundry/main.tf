resource "azurerm_cognitive_account" "foundry" {
  name                = "ais-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "AIServices"
  sku_name            = var.sku
  tags                = var.tags

  custom_subdomain_name              = "ais-${var.name_prefix}-${var.suffix}"
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

module "private_endpoint" {
  source = "../private_endpoint"

  name                           = "pe-${var.name_prefix}-foundry"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_cognitive_account.foundry.id
  subresource_names              = ["account"]
  private_dns_zone_ids           = var.private_dns_zone_ids
  tags                           = var.tags
}

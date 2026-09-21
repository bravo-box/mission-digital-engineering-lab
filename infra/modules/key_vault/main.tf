resource "azurerm_key_vault" "lab" {
  name                = trimsuffix(substr("kv-${var.name_prefix}-${var.suffix}", 0, 24), "-")
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

locals {
  administrators = toset(concat([var.current_principal_id], var.admin_object_ids))
}

resource "azurerm_role_assignment" "admin" {
  for_each = local.administrators

  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

module "private_endpoint" {
  source = "../private_endpoint"

  name                           = "pe-${var.name_prefix}-key-vault"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_key_vault.lab.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [var.private_dns_zone_id]
  tags                           = var.tags
}

# Key vault for lab secrets. RBAC only, no public endpoint.
resource "azurerm_key_vault" "lab" {
  name                = substr("kv-${var.name_prefix}-${local.suffix}", 0, 24)
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = local.tags

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
  key_vault_admins = toset(concat([data.azurerm_client_config.current.object_id], var.key_vault_admin_object_ids))
}

resource "azurerm_role_assignment" "key_vault_admin" {
  for_each = local.key_vault_admins

  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

module "pe_key_vault" {
  source = "./modules/private_endpoint"

  name                           = "pe-${var.name_prefix}-key-vault"
  location                       = azurerm_resource_group.lab.location
  resource_group_name            = azurerm_resource_group.lab.name
  subnet_id                      = azurerm_subnet.lab["key_vault"].id
  private_connection_resource_id = azurerm_key_vault.lab.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.lab["vault"].id]
  tags                           = local.tags
}
